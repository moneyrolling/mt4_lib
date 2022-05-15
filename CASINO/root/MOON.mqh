extern string _tmp2_ = "===== MOON SETTINGS =====";
extern bool DrawFullMoon=true;
extern color FullMoonLineColor=Crimson;
extern bool DrawNewMoon=true;
extern color NewMoonLineColor=Aqua;
extern datetime StartDate= D'2006.01.01 00:00';
extern datetime EndDate= D'2021.07.01 00:00';
//extern string OutFileName="FullMoonDates_out.csv";
extern int ChartTimeMinusGMTInMinutes = 120;

class clsMoon
{
    public:
       clsMoon(string strInputSymbol, int intInputTF);
       ~clsMoon();
       void    DeleteDraw();
       virtual void    Updater(datetime time, bool preloop=false);
       bool    blNewBar(bool use_first=true);
       int     latest_state;
       void    Plot();
    protected:
       //function to inherit
       string  strIdentifier;
       int     intMaxStore;
       int     intPeriod;
       string  strSymbol;
       void    Oninit();
       void    Preloop();
       void    MoonCalculate(datetime latest_date);
       void    StoreIndi(double value, double &values[]);
       
       
};

clsMoon::clsMoon(string strInputSymbol,int intInputTF)
{
    this.strSymbol = strInputSymbol;
    this.intPeriod = intInputTF;
    this.Oninit();
}

clsMoon::~clsMoon(){
   this.DeleteDraw();
}

void clsMoon::Oninit(void)
{
   this.latest_state = 0;
   this.strIdentifier = "Moon";
}

void clsMoon::DeleteDraw(void)
{
     for (int i=ObjectsTotal()-1; i >= 0; i--) 
     {
         string obj_name = ObjectName(i); 
         if(StringFind(obj_name,this.strIdentifier)>=0)
         {
             ObjectDelete(0,obj_name);
         }
     }
}

void clsMoon::Updater(datetime time,bool preloop=false)
{
    this.MoonCalculate(time);
   
}

bool clsMoon::blNewBar(bool use_first=true)
{
    static datetime save_time = 0;
    if(save_time == 0)
    {
         save_time = iTime(this.strSymbol,this.intPeriod,0);
         if(use_first)
         {
              return(true);
         }
    }
    else
    {
         if(save_time != iTime(this.strSymbol,this.intPeriod,0))
         {
              return(true);
         }
    }
    return(false);
}


void clsMoon::MoonCalculate(datetime latest_date)
{
   int BarsForOpenLine=10*24*60/this.intPeriod;
   double SecondsPerDay=60*60*24;
   int fullmoon_index = 0;
   for(int i = 1; i < 300; i++)
   {
        datetime FullMoonTime=(datetime)(StrToTime("2000.01.01 00:00")+MathRound(SecondsPerDay*(20.362954+29.5305888531*i+0.00000000010219*i*i)+ChartTimeMinusGMTInMinutes*60));
        if(FullMoonTime > latest_date)
        {
            fullmoon_index = i - 1;
            break;
        }
   }
   
   datetime last_fullmoon_time = (datetime)(StrToTime("2000.01.01 00:00")+MathRound(SecondsPerDay*(20.362954+29.5305888531*fullmoon_index+0.00000000010219*fullmoon_index*fullmoon_index)+ChartTimeMinusGMTInMinutes*60));
   
   
   int newmoon_index = 0;
   for(int j = 1; j < 300; j++)
   {
        datetime NewMoonTime=(datetime)(StrToTime("2000.01.01 00:00")+MathRound(SecondsPerDay*(5.597661+29.5305888610*j+0.00000000010219*j*j)+ChartTimeMinusGMTInMinutes*60));
        if(NewMoonTime > latest_date)
        {
            newmoon_index = j - 1;
            break;
        }
   }
   
   datetime last_newmoon_time = (datetime)(StrToTime("2000.01.01 00:00")+MathRound(SecondsPerDay*(5.597661+29.5305888610*newmoon_index+0.00000000010219*newmoon_index*newmoon_index)+ChartTimeMinusGMTInMinutes*60));
   if(last_fullmoon_time>last_newmoon_time)
   {
       this.latest_state = 1; //full moon
   }
   
   if(last_newmoon_time > last_fullmoon_time)
   {
       this.latest_state = 2; //new moon
   }
}

void clsMoon::Plot(void)
{
   this.DeleteDraw();
   string tag;
   switch(this.latest_state)
   { 
       
       case 1:
           tag  = this.strIdentifier+"_phase";
           ObjectCreate(tag, OBJ_LABEL, 0, 0, 0);// Creating obj.
           ObjectSet(tag, OBJPROP_CORNER, 1);    // Reference corner
           ObjectSet(tag, OBJPROP_XDISTANCE, 0);// X coordinate
           ObjectSet(tag, OBJPROP_YDISTANCE, 0);// Y coordinate
           ObjectSetInteger(0,tag,OBJPROP_COLOR,FullMoonLineColor);
           ObjectSetString(0,tag,OBJPROP_TEXT,"Full Moon Buy Phase");
           break;
       case 2:
           tag  = this.strIdentifier+"_phase";
           ObjectCreate(tag, OBJ_LABEL, 0, 0, 0);// Creating obj.
           ObjectSet(tag, OBJPROP_CORNER, 1);    // Reference corner
           ObjectSet(tag, OBJPROP_XDISTANCE, 0);// X coordinate
           ObjectSet(tag, OBJPROP_YDISTANCE, 0);// Y coordinate
           ObjectSetInteger(0,tag,OBJPROP_COLOR,NewMoonLineColor);
           ObjectSetString(0,tag,OBJPROP_TEXT,"New Moon Sell Phase");
           break;
   }
   //string upper_tag  = this.strIdentifier+"_buy_phase";
   
}

