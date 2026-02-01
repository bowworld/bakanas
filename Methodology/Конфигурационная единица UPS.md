---
- Key: UPSInfo
  Name: Информация об ИБП
  Input:
    Type: Dummy
  Sub:
  - Key: Model
    Name: Модель ИБП
    Searchable: 1
    Input:
      ReferencedCIClassLinkDirection: Reverse
      ReferencedCIClassLinkType: RelevantTo
      ReferencedCIClassName: Model
      ReferencedCIClassReferenceAttributeKey: Name
      SearchInputType: AutoComplete
      Type: CIClassReference
  - Key: SerialNumber
    Name: Серийный номер ИБП
    Searchable: 1
    Input:
      MaxLength: 100
      Size: 50
      Type: Text
  - Key: WarrantyExpirationDate
    Name: Гарантия до
    Searchable: 1
    Input:
      Type: Date
      YearPeriodFuture: 10
      YearPeriodPast: 20
  - Key: InstallDate
    Name: Установлен
    Searchable: 1
    Input:
      Required: 1
      Type: Date
      YearPeriodFuture: 10
      YearPeriodPast: 20
  - Key: Note
    Name: Заметки
    Searchable: 1
    Input:
      Required: 0
      Type: TextArea
  - Key: InvertorialNumber
    Name: Инвентарный номер
    Searchable: 1
    Input:
      MaxLength: 50
      Required: 0
      Size: 50
      Type: Text
  - Key: LoadPercentage
    Name: Процент загрузки ИБП
    Searchable: 0
    Input:
      Type: Text
      Required: 1
      Size: 3
      MaxLength: 3
      RegEx: ^\d+$
      RegExErrorMessage: Нужно вводить только цифры
      ValueMin: 1
      ValueMax: 999
      ValueDefault: 1
- Key: CurrentMetrics
  Name: Уставки
  Searchable: 0
  Input:
    Type: Dummy
  Sub:
  - Key: InputVoltage
    Name: Входные напряжения (V)
    Searchable: 0
    Input:
      Type: Dummy
    Sub:
    - Key: InputPHNum
      Name: Номер фазы
      Searchable: 0
      Input:
        Type: GeneralCatalog
        Class: ITSM::ConfigItem::UPS::PHNum
        CountMin: 1
        CountMax: 3
        CountDefault: 1
      Sub:
      - Key: InputPHVoltage
        Name: Напряжение на фазе (V)
        Searchable: 0
        Input:
          Type: Text
          MaxLength: 3
          Required: 0
          RegEx: ^\d+$
          RegExErrorMessage: Нужно вводить только цифры
          ValueMin: 1
          ValueMax: 999
          ValueDefault: 230
    - Key: InputFreq
      Name: Входная частота (Hz)
      Searchable: 0
      Input:
        Type: Text
        MaxLength: 3
        Required: 0
        RegEx: ^\d+$
        RegExErrorMessage: Нужно вводить только цифры
        ValueMin: 1
        ValueMax: 999
        ValueDefault: 50
  - Key: BypassVoltage
    Name: Напряжения байпаса
    Searchable: 0
    Input:
      Type: Dummy
    Sub:
    - Key: BypassPHNum
      Name: Номер фазы
      Searchable: 0
      Input:
        Type: GeneralCatalog
        Class: ITSM::ConfigItem::UPS::PHNum
        CountMin: 1
        CountMax: 3
        CountDefault: 1
      Sub:
      - Key: BypassPHVoltage
      Name: Напряжение на фазе (V)
      Searchable: 0
      Input:
        Type: Text
        MaxLength: 3
        Required: 0
        RegEx: \d+$
        RegExErrorMessage: Нужно вводить только цифры
        ValueMin: 1
        ValueMax: 999
        ValueDefault: 230
    - Key: BypassFreq
      Name: Частота на байпасе (Hz)
      Searchable: 0
      Input:
        Type: Text
        MaxLength: 3
        Required: 0
        RegEx: \d+$
        RegExErrorMessage: Нужно вводить только цифры
        ValueMin: 1
        ValueMax: 999
        ValueDefault: 50
  - Key: OutputVoltage
    Name: Выходные напряжения
    Searchable: 0
    Input:
      Type: Dummy
    Sub:
    - Key: OutputPHNum
      Name: Номер фазы
      Searchable: 0
      Input:
        Type: GeneralCatalog
        Class: ITSM::ConfigItem::UPS::PHNum
        CountMin: 1
        CountMax: 3
        CountDefault: 1
      Sub:
      - Key: OutputPHVoltage
        Name: Напряжение на фазе (V)
        Searchable: 0
        Input:
          Type: Text
          MaxLength: 3
          Required: 0
          RegEx: \d+$
          RegExErrorMessage: Нужно вводить только цифры
          ValueMin: 1
          ValueMax: 999
          ValueDefault: 230
    - Key: OutputFreq
      Name: Частота на выходе
      Searchable: 0
      Input:
        Type: Text
        MaxLength: 3
        Required: 0
        RegEx: \d+$
        RegExErrorMessage: Нужно вводить только цифры
        ValueMin: 1
        ValueMax: 999
        ValueDefault: 50
  - Key: OutputCurrent
    Name: Ток на выходе ИБП
    Searchable: 0
    Input:
      Type: Dummy
    Sub:
    - Key: OutputPhNumCurrent
      Name: Номер фазы
      Searchable: 0
      Input:
        Type: GeneralCatalog
        Class:: ITSM::ConfigItem::UPS::PHNum
        CountMin: 1
        CountMax: 3
        CountDefault: 1
      Sub:
      - Key: OutputCurrentByPH
        Name: Значение тока на выходе (A)
        Searchable: 0
        Input:
          Type: Text
          MaxLength: 3
          Required: 0
          RegEx: \d+$
          RegExErrorMessage: Нужно вводить только цифры
          ValueMin: 1
          ValueMax: 999
          ValueDefault: 1