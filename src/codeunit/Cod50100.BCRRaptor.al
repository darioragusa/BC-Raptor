codeunit 50100 "BCR Raptor"
{
    procedure Roar(FieldValue: Text)
    begin
        if not GuiAllowed() then exit;
        if not LowerCase(FieldValue).Contains('raptor') then exit;
        Page.RunModal(Page::"BCR Raptor Page");
    end;
}
