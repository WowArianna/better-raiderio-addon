const fetch = require('node-fetch');
const csv = require('fast-csv');

(async () => {

    const build = '9.1.0.39229', expansion = 8; // 9.X (Shadowlands)
    // const build = '8.3.7.35284', expansion = 7; // 8.X (Battle for Azeroth)

    if (!/^\d+\.\d+\.\d+\.\d+$/.test(build) || typeof expansion !== 'number') return console.error('Missing valid build and/or expansion id.');
    console.info(`Downloading data for game version ${build} and expansion ${expansion}`);

    const files = [
        {
            name: 'groupfinderactivity',
            fields: {
                'MapID': 'instance_map_id',
                'ID': 'lfd_activity_ids'
            }
        },
        {
            name: 'mapchallengemode',
            fields: {
                'MapID': 'instance_map_id', // reference
                'ID': 'keystone_instance',
                'Name_lang': 'name'
            }
        },
        {
            name: 'areatable',
            fields: {
                'ContinentID': 'instance_map_id', // reference
                'ID': 'id',
                'ZoneName': 'shortName'
            }
        },
        {
            name: 'map',
            fields: {
                'ID': 'instance_map_id', // reference
                'ExpansionID': 'expansion'
            }
        }
    ];

    const parseCsv = async (text) => {
        return new Promise(resolve => {
            const data = [];
            csv.parseString(text, { headers: true })
                .on('error', error => resolve(null))
                .on('data', row => data.push(row))
                .on('end', rowCount => resolve(data, rowCount));
        });
    };

    const dungeons = [];

    const getDungeon = (temp) => {
        for (let i = 0; i < dungeons.length; i++) {
            const dungeon = dungeons[i];
            if (
                (dungeon.instance_map_id !== undefined && dungeon.instance_map_id === temp.instance_map_id) ||
                (dungeon.keystone_instance !== undefined && dungeon.keystone_instance === temp.keystone_instance) ||
                (dungeon.id !== undefined && dungeon.id === temp.id) ||
                (dungeon.name !== undefined && dungeon.name === temp.name) ||
                (dungeon.shortName !== undefined && dungeon.shortName === temp.shortName) ||
                (dungeon.lfd_activity_ids !== undefined && dungeon.lfd_activity_ids === temp.lfd_activity_ids) ||
                (dungeon.lfd_activity_ids !== undefined && Array.isArray(dungeon.lfd_activity_ids) && dungeon.lfd_activity_ids.indexOf(temp.lfd_activity_ids) > -1) ||
                (dungeon.lfd_activity_ids !== undefined && Array.isArray(temp.lfd_activity_ids) && temp.lfd_activity_ids.indexOf(dungeon.lfd_activity_ids) > -1) ||
                (dungeon.lfd_activity_ids !== undefined && Array.isArray(dungeon.lfd_activity_ids) && Array.isArray(temp.lfd_activity_ids) && dungeon.lfd_activity_ids.indexOf(temp.lfd_activity_ids[0]) > -1)
            ) {
                return dungeon;
            }
        }
    };

    const mergeDungeons = (existingDungeon, temp) => {
        for (let key in temp) {
            const newVal = temp[key];
            let oldVal = existingDungeon[key];
            if (oldVal === undefined) {
                existingDungeon[key] = newVal;
            } else if (oldVal !== newVal) {
                if (key === 'id' || key === 'shortName') {
                    continue;
                }
                if (!Array.isArray(oldVal)) {
                    oldVal = existingDungeon[key] = [ oldVal ];
                }
                if (oldVal.indexOf(newVal) < 0) {
                    oldVal.push(newVal);
                }
            }
        }
    };

    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const request = await fetch(`https://wow.tools/dbc/api/export/?name=${file.name}&build=${build}`, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
        });
        const text = await request.text();
        file.rows = await parseCsv(text);
        if (!file.rows)
            continue;
        for (let j = 0; j < file.rows.length; j++) {
            const row = file.rows[j];
            const temp = {};
            for (let field in file.fields) {
                const key = file.fields[field];
                const newVal = row[field];
                let oldVal = temp[key];
                if (oldVal === undefined) {
                    oldVal = temp[key] = newVal;
                } else {
                    if (!Array.isArray(oldVal)) {
                        oldVal = temp[key] = [ oldVal ];
                    }
                    if (oldVal.indexOf(newVal) < 0) {
                        oldVal.push(newVal);
                    }
                }
            }
            const existingDungeon = getDungeon(temp);
            if (!existingDungeon) {
                dungeons.push(temp);
            } else {
                mergeDungeons(existingDungeon, temp);
            }
        }
    }

    for (let i = 0; i < dungeons.length; i++) {
        const dungeon = dungeons[i];
        for (let key in dungeon) {
            let val = dungeon[key];
            if (Array.isArray(val) && val.length < 2) {
                val = dungeon[key] = val[0];
            }
            if (typeof val === 'string' && /^\d+$/.test(val)) {
                val = dungeon[key] = parseInt(val);
            }
            if (Array.isArray(val)) {
                for (let j = 0; j < val.length; j++) {
                    if (typeof val[j] === 'string') {
                        if (/^\d+$/.test(val[j])) {
                            val[j] = parseInt(val[j]);
                        } else {
                            val[j] = '"' + val[j].replace(/\"/, '\\"') + '"';
                        }
                    }
                }
            }
        }
    }

    const isDungeonValid = (dungeon) => dungeon !== undefined && dungeon.id !== undefined && dungeon.expansion === expansion && dungeon.keystone_instance !== undefined && dungeon.lfd_activity_ids !== undefined && dungeon.name !== undefined;

    const file_groupfinderactivity_rows = files.filter(file => file.name === 'groupfinderactivity')[0].rows;
    const file_mapchallengemode_rows = files.filter(file => file.name === 'mapchallengemode')[0].rows;

    for (let i = dungeons.length - 1; i >= 0; i--) {
        const dungeon = dungeons[i];
        if (!isDungeonValid(dungeon) || !Array.isArray(dungeon.keystone_instance)) continue;
        const dungeonSplits = [];
        for (let j = 0; j < dungeon.keystone_instance.length; j++) {
            const dungeonSplit = {
                instance_map_id: dungeon.instance_map_id,
                lfd_activity_ids: [],
                keystone_instance: dungeon.keystone_instance[j],
                name: '',
                id: dungeon.id,
                shortName: Array.isArray(dungeon.shortName) ? dungeon.shortName[0] : dungeon.shortName,
                expansion: dungeon.expansion
            };
            const keystoneRows = file_mapchallengemode_rows.filter(row => row.ID == dungeonSplit.keystone_instance);
            if (keystoneRows.length) {
                const activityRows = file_groupfinderactivity_rows.filter(row => row.MapID == dungeonSplit.instance_map_id);
                if (activityRows.length) {
                    for (let k = 0; k < activityRows.length; k++) {
                        dungeonSplit.lfd_activity_ids.push(parseInt(activityRows[k].ID));
                    }
                }
                dungeonSplit.name = keystoneRows[0].Name_lang;
                dungeonSplits.push(dungeonSplit);
            }
        }
        if (dungeonSplits.length) {
            dungeons.splice(i, 1);
            for (let k = 0; k < dungeonSplits.length; k++) {
                const dungeonSplit = dungeonSplits[k];
                dungeonSplit.id += 1000000 * (k + 1);
                dungeons.push(dungeonSplit);
            }
        }
    }

    const timerFile = files.filter(file => file.name === 'mapchallengemode')[0];
    const getTimerInfoForDungeon = dungeon => {
        if (!timerFile || !timerFile.rows)
            return;
        const dungeonRow = timerFile.rows.filter(row => row['ID'] - dungeon.keystone_instance === 0)[0];
        if (!dungeonRow)
            return;
        const goldTimer = parseInt(dungeonRow['CriteriaCount[2]']) || 0;
        const silverTimer = parseInt(dungeonRow['CriteriaCount[1]']) || 0;
        const bronzeTimer = parseInt(dungeonRow['CriteriaCount[0]']) || 0;
        return { goldTimer, silverTimer, bronzeTimer };
    };

    dungeons.forEach(dungeon => {
        const timerInfo = getTimerInfoForDungeon(dungeon);
        dungeon.timers = timerInfo ? [ timerInfo.goldTimer, timerInfo.silverTimer, timerInfo.bronzeTimer ] : [];
    });

    dungeons.sort((a, b) => a.id - b.id);

    const sortedKeys = [
        'id',
        'keystone_instance',
        'instance_map_id',
        'lfd_activity_ids',
        'timers',
        'name',
        'shortName'
    ];

    const lua = [];

    for (let i = 0; i < dungeons.length; i++) {
        const dungeon = dungeons[i];
        if (!isDungeonValid(dungeon)) continue;
        if (Array.isArray(dungeon.keystone_instance)) {
            console.warn(`Dungeon #${dungeon.id} needs to be manually separated into two entries!`);
        }
        const lualine = ['\t[' + (lua.length + 1) + '] = {'];
        for (let j = 0; j < sortedKeys.length; j++) {
            const sortedKey = sortedKeys[j];
            let val = dungeon[sortedKey];
            if (typeof val === 'string') {
                val = '"' + val.replace(/\"/, '\\"') + '"';
            } else if (Array.isArray(val)) {
                val = '{ ' + val.join(', ') + ' }';
            }
            lualine.push(`\t\t["${sortedKey}"] = ${val},`);
        }
        lualine.push('\t}');
        lua.push(lualine.join('\r\n'));
    }

    console.log('local _, ns = ...\r\n\r\n-- Dungeon listing sorted by id\r\nns.dungeons = {\r\n' + lua.join(',\r\n') + '\r\n}\r\n');

})();
