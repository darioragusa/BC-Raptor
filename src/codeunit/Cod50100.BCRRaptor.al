codeunit 50100 "BCR Raptor"
{
    procedure Roar(FieldValue: Text)
    begin
        if not GuiAllowed() then exit;
        if not LowerCase(FieldValue).Contains('raptor') then exit;
        Roar();
    end;

    procedure Roar()
    begin
        Page.RunModal(Page::"BCR Raptor Page");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure GetGlobalTableTriggerMask(TableID: Integer; var TableTriggerMask: Integer)
    begin
        // 0 0 0 0
        // │ │ │ └−−−−−− Insert
        // │ │ └−−−−−−−− Modify
        // │ └−−−−−−−−−− Delete
        // └−−−−−−−−−−−− Rename
        TableTriggerMask := 11;
        // According to these gentlemen, the trigger only runs for changes made by users, we should be fine
        // https://forum.mibuso.com/discussion/35120/onglobalmodify
        // "On GlobalModify Trigger in CU 1 gets triggered when a user modifies a record."
        // https://forum.mibuso.com/discussion/41269/change-log-data-migration
        // "These triggers are only called when a user directly changes data using a form or table. All changes from reports, codeunit, dataport or xmlports are ignored as are any changes from code on any object."
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalModify', '', false, false)]
    procedure OnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        LookForRaptors(RecRef, xRecRef, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalRename', '', false, false)]
    procedure OnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        LookForRaptors(RecRef, xRecRef, 8);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    procedure OnGlobalInsert(RecRef: RecordRef)
    begin
        LookForRaptors(RecRef, RecRef, 1);
    end;

    local procedure LookForRaptors(RecRef: RecordRef; xRecRef: RecordRef; Action: Integer)
    var
        Field: Record Field;
        Class: Option Normal,FlowField,FlowFilter;
        ObsoleteState: Option No,Pending,Removed;
        FldVal: Text;
        Roar: Boolean;
        Word: Label 'raptor';
    begin
        Field.SetRange(TableNo, RecRef.Number());
        Field.SetRange(Class, Class::Normal);
        Field.SetRange(ObsoleteState, ObsoleteState::No);
        Field.SetFilter(Type, '%1|%2', 31488, 31489);
        if Action = 8 then
            Field.SetRange(IsPartOfPrimaryKey, true);
        if Field.FindSet() then
            repeat
                FldVal := RecRef.Field(Field."No.").Value();
                Roar := LowerCase(FldVal).Contains(Word);
                if Roar then begin
                    if Action in [2, 8] then begin
                        FldVal := xRecRef.Field(Field."No.").Value();
                        Roar := not LowerCase(FldVal).Contains(Word);
                    end;
                end;
            until Roar or (Field.Next() = 0);
        if Roar then
            Roar();
    end;
}
