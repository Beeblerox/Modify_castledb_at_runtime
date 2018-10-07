class Game extends hxd.App
{
    static function main()
    {
        // Инициализация системы ресурсов Heaps
        #if hl
        // В HashLink будем работать с файлами локально
        hxd.Res.initLocal();
        #else
        // В JavaScript будем использовать встраиваемые в js-файл данные
        hxd.Res.initEmbed();
        #end
        new Game();
    }

    public function getById(db:cdb.Database, sheetName:String, id:String):Dynamic
    {
        var sheet = db.getSheet(sheetName);
        var sheetColumns = sheet.columns;

        var idField = null;
        for (column in sheetColumns)
        {
            switch (column.type)
            {
                case cdb.Data.ColumnType.TId:
                    idField = column.name;
                    break;
                
                default:

            }
        }

        if (idField == null)
        {
            return null;
        }

        var lines = sheet.lines;
        for (line in lines)
        {
            if (Reflect.field(line, idField) == id)
            {
                return line;
            }
        }

        return null;
    }

    public function getEnumValues(db:cdb.Database, sheetName:String, columnName:String):Array<String>
    {
        var sheet = db.getSheet(sheetName);
        var sheetColumns = sheet.columns;

        for (column in sheetColumns)
        {
            if (column.name == columnName)
            {
                switch (column.type)
                {
                    case TEnum(values):
                        return values;
                    default:

                }
            }
        }

        return null;
    }

    // Инициализация проекта
    @:access(cdb.Flags)
    override function init() 
    {
        // Загрузка данных для базы из файла data.cdb
        Data.load(hxd.Res.data.entry.getText());
        
        // Загружаем всю базу
        var db:cdb.Database = new cdb.Database();
        db.load(hxd.Res.data.entry.getText());

        // Доступ к листу по имени
        var collideSheet:cdb.Sheet = db.getSheet("collide");

        // Данные всех строк
        var lines:Array<Dynamic> = collideSheet.lines;
        
        // Упорядоченный список столбцов с их типами
        trace(collideSheet.columns);
        
        // Содержимое первой строки на листе
        trace(lines[0]);

        // Меняем id у строки с "No" на "MyNo"
        lines[0].id = "MyNo";

        var npcSheet:cdb.Sheet = db.getSheet("npc");
        var npcs = npcSheet.lines;
        
        // Посмотрим типы столбцов
        trace(npcSheet.columns);
        
        var enumValues:Array<String> = getEnumValues(db, "npc", "type");
        
        trace("enumValues: " + enumValues);

        // Первая строка на листе npc
        npcs[0].hasPortrait = false;
        trace(npcs[0]);
        trace("npc type: " + enumValues[npcs[0].type]);

        var imagesSheet:cdb.Sheet = db.getSheet("images");
        trace(imagesSheet.columns);

        var flagValues:Array<String> = [];
        for (column in imagesSheet.columns)
        {
            if (column.name == "stats")
            {
                switch (column.type)
                {
                    case cdb.Data.ColumnType.TFlags(values):
                        flagValues = values;
                    default:

                }
            }
        }

        trace("flagValues: " + flagValues);

        trace(imagesSheet.lines[1]);

        // Целочисленное представление столбца stats:
        trace(imagesSheet.lines[1].stats);

        // Попробуем прочитать записанные в него значения:
        var flags = new cdb.Types.Flags<Int>(imagesSheet.lines[1].stats);
        // Давайте уберем значение второго флага
        flags.unset(1);
        // Читаем значения каждого флага
        for (i in 0...flagValues.length)
        {
            trace(flagValues[i] + ": " + flags.has(i));
        }
        
        // Добавить строку на лист (вставим ее в самое начало листа)
        // Параметр показывает после какой строки добавлять на лист
        // Если его пропустить, то строка будет добавлена в конец
        var newLine:Dynamic = imagesSheet.newLine(-1); 
        newLine.name = "lion";
        newLine.x = 20;
        newLine.y = 400;
        // и выставим ему только третий флаг
        flags = new cdb.Types.Flags<Int>(0);
        flags.set(2);
        newLine.stats = flags;
        // Проверим, правильно ли мы установили флаг
        for (i in 0...flagValues.length)
        {
            trace(flagValues[i] + ": " + flags.has(i));
        }

        // Выведем нашу строку
        trace(newLine);

        // Попробуем считать "вложенную" таблицу - это столбец типа List (для них создаются скрытые от пользователя листы)
        var levelSheet:cdb.Sheet = db.getSheet("levelData");

        trace(levelSheet.columns);

        var secondLevel = levelSheet.lines[1];
        
        var subColumnParent:Dynamic = null;
        for (column in levelSheet.columns)
        {
            if (column.name == "npcs")
            {
                subColumnParent = column;
                break;
            }
        }

        // Узнаем типы столбцов во вложенном списке
        var subSheet = levelSheet.getSub(subColumnParent);
        trace(subSheet.columns);

        // Попробуем прочитать tile у записи, на которую ссылается первая запись npc на втором уровне
        var item = levelSheet.lines[1].npcs[0].item;
        trace("item: " + item);

        var items = db.getSheet("item").lines;
        for (it in items)
        {
            if (it.id == item)
            {
                // Нашли нашу запись
                trace(it.tile);
                break;
            }
        }

        var itemTile:cdb.Types.TilePos = getById(db, "item", item).tile;
        trace(itemTile);

        var newNPC = {
            x : 25, 
            y : 9, 
            kind : "Hero",  // Ссылка на лист npc
            item : "Key"    // Ссылка на лист item
        };

        levelSheet.lines[1].npcs.push(newNPC);
        trace(levelSheet.lines[1].npcs);
        
        // Сохраняем базу, а полученную строку можем сохранить удобным способом
        var newData:String = db.save();
    }
}