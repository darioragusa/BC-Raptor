controladdin "BCR Raptor View"
{
    Scripts = 'src\controladdin\Raptor\script.js';
    StyleSheets = 'src\controladdin\Raptor\style.css';

    HorizontalStretch = true;
    VerticalStretch = true;

    event OnStartup();
    event OnAnimationEnded();
    procedure Raptorize()
}