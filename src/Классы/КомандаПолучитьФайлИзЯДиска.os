
///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем OAuth_Токен;

// Интерфейсная процедура, выполняет регистрацию команды и настройку парсера командной строки
//   
// Параметры:
//   ИмяКоманды 	- Строка										- Имя регистрируемой команды
//   Парсер 		- ПарсерАргументовКоманднойСтроки (cmdline)		- Парсер командной строки
//
Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Получить файл из Yandex-Диск");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-params",
		"Файлы JSON содержащие значения параметров,
		|могут быть указаны несколько файлов разделенные "";""
		|(параметры командной строки имеют более высокий приоритет)");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-path",
		"Путь к локальному каталогу для сохранения загруженных файлов");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-token",
		"Token авторизации");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-file",
		"Путь к файлу на Yandex-Диск для загрузки");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-list",
		"Путь к файлу на Yandex-Диск со списком файлов,
		|которые будут загружены (параметр -ya-file игнорируется)");

	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, 
		"-delsrc",
		"Удалить исходные файлы после получения");

	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры // ЗарегистрироватьКоманду()

// Интерфейсная процедура, выполняет текущую команду
//   
// Параметры:
//   ПараметрыКоманды 	- Соответствие						- Соответствие параметров команды и их значений
//
// Возвращаемое значение:
//	Число - код возврата команды
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
	ЗапускПриложений.ПрочитатьПараметрыКомандыИзФайла(ПараметрыКоманды["-params"], ПараметрыКоманды);
	
	ЭтоСписокФайлов = Истина;
	
	ЦелевойПуть				= ПараметрыКоманды["-path"];
	OAuth_Токен				= ПараметрыКоманды["-ya-token"];

	ПутьНаДиске				= ПараметрыКоманды["-ya-list"];
	Если НЕ ЗначениеЗаполнено(ПутьНаДиске) Тогда
		ПутьНаДиске				= ПараметрыКоманды["-ya-file"];
		ЭтоСписокФайлов	= Ложь;
	КонецЕсли;

	УдалитьИсточник			= ПараметрыКоманды["-delsrc"];

	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();

	Если ПустаяСтрока(ЦелевойПуть) Тогда
		Лог.Ошибка("Не указана путь к каталогу для сохранения загруженных файлов");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ПустаяСтрока(OAuth_Токен) Тогда
		Лог.Ошибка("Не задан Token авторизации");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ПустаяСтрока(ПутьНаДиске) Тогда
		Лог.Ошибка("Не задан путь к файлу для получения из Yandex-Диск");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	ЯндексДиск = Неопределено;
	
	Попытка

		ПутьКСкачанномуФайлу = ПолучитьФайлИзЯДиска(ЯндексДиск, ПутьНаДиске, ЦелевойПуть, УдалитьИсточник);
	
		ФайлИнфо = Новый Файл(ПутьКСкачанномуФайлу);

		КаталогНаДиске = СтрЗаменить(ПутьНаДиске, ФайлИнфо.Имя, "");
	
		Если ЭтоСписокФайлов Тогда
			МассивПолучаемыхФайлов = ПрочитатьСписокФайлов(ПутьКСкачанномуФайлу);
			Для Каждого ПолучаемыйФайл Из МассивПолучаемыхФайлов Цикл
				ПутьКСкачанномуФайлу = ПолучитьФайлИзЯДиска(ЯндексДиск
														, КаталогНаДиске + ПолучаемыйФайл
														, ЦелевойПуть
														, УдалитьИсточник);
			КонецЦикла;
		КонецЕсли;

		Возврат ВозможныйРезультат.Успех;
	Исключение
		Лог.Ошибка(ОписаниеОшибки());
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецПопытки;

КонецФункции // ВыполнитьКоманду()

// Функция возвращает массив имен файлов архива
//   
// Параметры:
//   ПутьКСписку 	- Строка			- путь к файлу со списком файлов архива
//
// Возвращаемое значение:
//	Массив(Строка) - список файлов архива
//
Функция ПрочитатьСписокФайлов(ПутьКСписку)

	МассивФайловЧастей = Новый Массив();

	ЧтениеСписка = Новый ЧтениеТекста(ПутьКСписку, КодировкаТекста.UTF8);
	СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
	Пока СтрокаСписка <> Неопределено Цикл
		Если ЗначениеЗаполнено(СокрЛП(СтрокаСписка)) Тогда
			МассивФайловЧастей.Добавить(СтрокаСписка);
		КонецЕсли;
		
		СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
	КонецЦикла;
	
	ЧтениеСписка.Закрыть();

	Возврат МассивФайловЧастей;

КонецФункции // ПрочитатьСписокФайлов()

// Функция получения файла из Yandex-Диска
//
// Параметры:
//   ЯДиск		 		- ЯндексДиск				- объект ЯндексДиск для работы с yandex-диском
//   ПутьНаДиске 		- Строка					- расположение файла на yandex-диске
//   ЦелевойПуть 		- Строка					- путь, куда будет загружен файл
//   УдалитьИсточник 	- Булево					- Истина - удалить файл после загрузки
//
// Возвращаемое значение:
//	Число - код возврата команды
//
Функция ПолучитьФайлИзЯДиска(ЯДиск, Знач ПутьНаДиске, Знач ЦелевойПуть, УдалитьИсточник = Ложь)
	
	Если НЕ ЗначениеЗаполнено(ЯДиск) Тогда
		
		ЯДиск = Новый ЯндексДиск;
		ЯДиск.УстановитьТокенАвторизации(OAuth_Токен);
	КонецЕсли;
	
	ПутьКСкачанномуФайлу = "";
	
	Попытка
		ПутьКСкачанномуФайлу = ЯДиск.СкачатьФайлСДиска(ЦелевойПуть, ПутьНаДиске, Истина);

		Лог.Информация("Файл получен %1", ПутьКСкачанномуФайлу);
	Исключение
		Лог.Ошибка("Ошибка получения файла %1: %2", ПутьНаДиске, ИнформацияОбОшибке());
	КонецПопытки;

	Если УдалитьИсточник Тогда
		ЯДиск.Удалить(ПутьНаДиске, Истина);
		СвойстваДиска = ЯДиск.ПолучитьСвойстваДиска();
		Лог.Информация(СтрШаблон("Удален файл на Yandex-Диск %1", ПутьНаДиске));
		Лог.Отладка(СтрШаблон("Всего доступно %1 байт", СвойстваДиска.total_space));
		Лог.Отладка(СтрШаблон("Из них занято %1 байт", СвойстваДиска.used_space));
	КонецЕсли;
	
	Возврат ПутьКСкачанномуФайлу;

КонецФункции // ПолучитьФайлИзЯДиска()

Лог = Логирование.ПолучитьЛог("ktb.app.cpdb");