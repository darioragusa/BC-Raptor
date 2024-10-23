page 50100 "BCR Raptor Page"
{
    ApplicationArea = All;
    Caption = 'Raptor';
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            usercontrol(CurrView; "BCR Raptor View")
            {
                trigger OnStartup()
                begin
                    CurrPage.CurrView.Raptorize();
                end;

                trigger OnAnimationEnded()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }
}
