#include <Controls\Defines.mqh>
#undef CONTROLS_FONT_NAME 
#undef CONTROLS_FONT_SIZE 
#undef CONTROLS_BUTTON_COLOR
#undef CONTROLS_BUTTON_COLOR_BG
#undef CONTROLS_BUTTON_COLOR_BORDER
#undef CONTROLS_DIALOG_COLOR_BORDER_LIGHT
#undef CONTROLS_DIALOG_COLOR_BORDER_DARK
#undef CONTROLS_DIALOG_COLOR_BG
#undef CONTROLS_DIALOG_COLOR_CAPTION_TEXT
#undef CONTROLS_DIALOG_COLOR_CLIENT_BG
#undef CONTROLS_DIALOG_COLOR_CLIENT_BORDER 
string   font_name                  = "Trebuchet MS";
int      font_size                  = 10;
color    button_color               = C'0x3B,0x29,0x28';
color    button_color_bg            = C'0xDD,0xE2,0xEB';
color    button_color_border        = C'0xB2,0xC3,0xCF';
color    dialog_color_border_light  = White;
color    dialog_color_border_dark   = C'0xB6,0xB6,0xB6';
color    dialog_color_bg            = clrRed;
color    dialog_color_caption_text  = clrWhite;
color    dialog_color_client_bg     = clrGray;//C'0xF7,0xF7,0xF7';
color    dialog_color_client_border = C'0xC8,0xC8,0xC8';
#define CONTROLS_FONT_NAME                font_name
#define CONTROLS_FONT_SIZE                font_size

#define CONTROLS_BUTTON_COLOR             button_color
#define CONTROLS_BUTTON_COLOR_BG          button_color_bg
#define CONTROLS_BUTTON_COLOR_BORDER      button_color_border

#define CONTROLS_DIALOG_COLOR_BORDER_LIGHT dialog_color_border_light
#define CONTROLS_DIALOG_COLOR_BORDER_DARK dialog_color_border_dark
#define CONTROLS_DIALOG_COLOR_BG          dialog_color_bg
#define CONTROLS_DIALOG_COLOR_CAPTION_TEXT dialog_color_caption_text
#define CONTROLS_DIALOG_COLOR_CLIENT_BG   dialog_color_client_bg
#define CONTROLS_DIALOG_COLOR_CLIENT_BORDER dialog_color_client_border
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>


class clsTOGGLE : public CAppDialog
{
     public:
     
                        clsTOGGLE();
                        ~clsTOGGLE();
                        //--- chart event handler
          virtual bool  OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
     
     protected:
          void          Oninit();
          bool          CreateButton(); //create all main button and labels
          
     private:
          int           button_height;
          int           button_width;
          CButton       m_buy_button;
};

EVENT_MAP_BEGIN(clsTOGGLE)
EVENT_MAP_END(CAppDialog)

clsTOGGLE::clsTOGGLE(void)
{
     this.Oninit();
}

clsTOGGLE::~clsTOGGLE()
{
    this.Destroy();
}

void clsTOGGLE::Oninit(void)
{
    this.button_height  = 30;
    this.button_width   = 100;
    if(this.Create(0,"Toggle Assistant",0,20,20,100,100)) Print("UI Created");
    if(this.CreateButton()) Print("Button Created");
}

bool clsTOGGLE::CreateButton()
{
    int buy_button_x1 = 30;
    int buy_button_x2 = buy_button_x1 + this.button_width;
    int buy_button_y1 = 20;
    int buy_button_y2 = buy_button_y1 + this.button_height;
    if(!this.m_buy_button.Create(0,"TOGGLE SND",0,buy_button_x1,buy_button_y1,buy_button_x2,buy_button_y2)) return (false);
    if(!this.m_buy_button.Text("BUY")) return (false);
    if(!this.Add(m_buy_button)) return(false);
    return(true);
}