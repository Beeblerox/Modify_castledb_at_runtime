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

    // TODO: use it...
    public function getColumnByName(db:cdb.Database, sheetName:String, columnName:String):cdb.Data.Column
    {
        var sheet = db.getSheet(sheetName);
        var sheetColumns = sheet.columns;
        var refSheetName = null;
        for (column in sheetColumns)
        {
            if (column.name == columnName)
            {
                return column;
            }
        }

        return null;
    }

    public function getByRefId(db:cdb.Database, sheetName:String, columnName:String, id:String):Dynamic
    {
        var refColumn = getColumnByName(db, sheetName, columnName);
        if (refColumn == null)
        {
            return null;
        }

        var refSheetName = null;
        switch (refColumn.type)
        {
            case TRef(sheet):
                refSheetName = sheet;
            default:

        }

        if (refSheetName == null)
        {
            return null;
        }

        return getById(db, refSheetName, id);
    }

    public function getIdField(db:cdb.Database, sheetName:String):String
    {
        var sheet = db.getSheet(sheetName);
        var sheetColumns = sheet.columns;
        for (column in sheetColumns)
        {
            switch (column.type)
            {
                case cdb.Data.ColumnType.TId:
                    return column.name;
                default:

            }
        }

        return null;
    }

    public function getIndexById(db:cdb.Database, sheetName:String, id:String):Int
    {
        var idField = getIdField(db, sheetName);
        if (idField == null)
        {
            return null;
        }

        var sheet = db.getSheet(sheetName);
        var lines = sheet.lines;
        for (i in 0...lines.length)
        {
            var line = lines[i];
            if (Reflect.field(line, idField) == id)
            {
                return i;
            }
        }

        return -1;
    }

    public function getById(db:cdb.Database, sheetName:String, id:String):Dynamic
    {
        var idField = getIdField(db, sheetName);
        if (idField == null)
        {
            return null;
        }

        var sheet = db.getSheet(sheetName);
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

    public function getEnumNames(db:cdb.Database, sheetName:String, columnName:String):Array<String>
    {
        var column = getColumnByName(db, sheetName, columnName);
        if (column == null)
        {
            return null;
        }

        switch (column.type)
        {
            case TEnum(values):
                return values;
            default:

        }

        return null;
    }

    public function getEnumValue(db:cdb.Database, sheetName:String, columnName:String, index:Int):String
    {
        return getEnumNames(db, sheetName, columnName)[index];
    }

    public function getFlagNames(db:cdb.Database, sheetName:String, columnName:String):Array<String>
    {
        var column = getColumnByName(db, sheetName, columnName);
        if (column == null)
        {
            return null;
        }

        switch (column.type)
        {
            case cdb.Data.ColumnType.TFlags(values):
                return values;
            default:

        }

        return null;
    }

    @:access(cdb.Flags)
    public function getFlagValues(db:cdb.Database, sheetName:String, columnName:String, value:Int):Map<String, Bool>
    {
        var flagNames = getFlagNames(db, sheetName, columnName);
        var flags = new cdb.Types.Flags<Int>(value);
        var result:Map<String, Bool> = new Map<String, Bool>();

        for (i in 0...flagNames.length)
        {
            result.set(flagNames[i], flags.has(i));
        }
        
        return result;
    }

    public function deleteLineById(db:cdb.Database, sheetName:String, id:String):Bool
    {
        var index:Int = getIndexById(db, sheetName, id);
        if (index < 0)
        {
            return false;
        }
        
        var sheet = db.getSheet(sheetName);
        sheet.deleteLine(index);
        return true;
    }

    // Инициализация проекта
    @:access(cdb.Flags)
    override function init() 
    {
        // Загрузка данных для базы из файла data.cdb
        Data.load(hxd.Res.data.entry.getText());
        /*
        var fields = Reflect.fields(Data);
        trace(fields);

        fields = Reflect.fields(Data.collide);
        trace(fields);

        fields = Reflect.fields(Reflect.field(Data.collide, "sheet"));
        trace(fields);

        var sheet = Reflect.field(Data.collide, "sheet");
        trace(sheet.lines.length);
        */
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
        
        var enumNames:Array<String> = getEnumNames(db, "npc", "type");
        trace("enumValues: " + enumNames);

        // Первая строка на листе npc
        npcs[0].hasPortrait = false;
        trace(npcs[0]);
        trace("npc type: " + getEnumValue(db, "npc", "type", npcs[0].type));

        var imagesSheet:cdb.Sheet = db.getSheet("images");
        trace(imagesSheet.columns);

        var flagValues:Array<String> = getFlagNames(db, "images", "stats");
        trace("flagValues: " + flagValues);

        trace(imagesSheet.lines[1]);

        // Целочисленное представление столбца stats:
        trace(imagesSheet.lines[1].stats);

        // Попробуем прочитать записанные в него значения:
        var flags = new cdb.Types.Flags<Int>(imagesSheet.lines[1].stats);
        // Давайте уберем значение второго флага
        flags.unset(1);
        // Читаем значения каждого флага
        var flagValues = getFlagValues(db, "images", "stats", imagesSheet.lines[1].stats);
        for (key in flagValues.keys())
        {
            trace(key + ": " + flagValues.get(key));
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
        flagValues = getFlagValues(db, "images", "stats", newLine.stats);
        for (key in flagValues.keys())
        {
            trace(key + ": " + flagValues.get(key));
        }

        // Выведем нашу строку
        trace(newLine);

        // Попробуем считать "вложенную" таблицу - это столбец типа List (для них создаются скрытые от пользователя листы)
        var levelSheet:cdb.Sheet = db.getSheet("levelData");

        trace(levelSheet.columns);

        var secondLevel = levelSheet.lines[1];
        
        // TODO: improve this example...
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

        // Находим по ссылке тайл записи, на которую ссылается запись item:
        var referencedTile:cdb.Types.TilePos = getById(db, "item", item).tile;
        trace("referencedTile: " + referencedTile);

        var newNPC = {
            x : 25, 
            y : 9, 
            kind : "Hero",  // Ссылка на лист npc
            item : "Key"    // Ссылка на лист item
        };

        levelSheet.lines[1].npcs.push(newNPC);
        trace(levelSheet.lines[1].npcs);

        trace(levelSheet.lines.length);

        trace("before deletion: " + imagesSheet.lines.length);
        deleteLineById(db, "images", "sloth");
        trace("after deletion: " + imagesSheet.lines.length);

        // Сохраняем базу, а полученную строку можем сохранить удобным способом
        var newData:String = db.save();
    }
}