enum DIRECTION
{
    NEUTRAL = 0,
    LONG    = 1,
    SHORT   = 2
};
#include "/MASTER_BOT.mqh"
#include "/SND_OPTIMIZED.mqh"
#include "/SEASONALITY.mqh"
#include "/GSHEET_DIRECTIONS.mqh"
input color SND2_ColorSupport = clrAqua;   // SND TF 2 Support Color
input color SND2_ColorResistance = clrPurple; // SND TF 2 Resistance Color
input color SND3_ColorSupport = clrGreenYellow;   // SND TF 3 Support Color
input color SND3_ColorResistance = clrMagenta; // SND TF 3 Resistance Color
#include "/FIBO.mqh"
#include "/SESSION.mqh"
#include "/TRADE_ENHANCER.mqh"

enum   BE_MODE  
{
    PIP_MODE    = 1,
    PECENT_MODE = 2
};

enum  SND_SELECTION_MODE
{
    INPUT_MODE  = 1,
    TOGGLE_MODE = 2
};



//BOT SPECIFIC INPUT
extern string _tmp4_ = "===== BOT INPUT =====";
extern bool use_rb  = true;
extern bool use_snd_direction = true;
extern bool use_snd = true;
extern SND_SELECTION_MODE snd_selection = 1; 
extern SND_MODE input_snd_mode = 1; 
SND_MODE final_snd_mode = snd_selection == 1 ? input_snd_mode : FreshZoneOnly ? (SND_MODE)2 : (SND_MODE)1;

extern period SND_TIMEFRAME_1 = D1;
extern period SND_TIMEFRAME_2 = D1;
extern period SND_TIMEFRAME_3 = M1;
extern bool use_struc = true;
extern period STRUC_TIMEFRAME = H4;
extern bool use_fibo  = true; 
extern string _tmp5_ = "===== STRATEGY INPUT =====";
extern int  entry_magic_number = 98765;
extern double equity_cut_percent = 1;
extern int  sl_x_pip = 2; 
extern double RR_Ratio = 1;
extern string _tmp6_ = "===== BREAKEVEN SETTINGS =====";
extern bool   Use_BreakEven = true;
extern BE_MODE Breakeven_Mode = 1; 
extern double BreakEven_Input = 30;
extern string _tmp7_ = "===== TRAILING SETTINGS =====";
extern bool   Use_Trailing = true;
extern double Trailing_Percent_Input = 3;
extern string _tmp8_ = "===== SESSION SETTINGS =====";
extern bool      Use_DayClose = true;
extern bool      Use_Session_Filter = true;
extern DIRECTION London_Session   = SHORT;
extern DIRECTION NewYork_Session  = LONG;
extern DIRECTION Tokyo_Session    = NEUTRAL;
extern int BasketPrimaryAlertCount = 4;
string trade_comment = "EUPORIAFX";

//declare object
clsSND *SND_TF1;
clsSND *SND_TF2;
clsSND *SND_TF3;
clsStructure *STRUC;
clsFibo *FIBO;
clsSeason *SEASON;
clsGsheet *GSHEET;
clsSession *SESSION;
clsMasterIndi *DAYCOUNTER;
clsTradeEnhancer *ENHANCER;


class clsBot03 : 
     public  clsMasterBot
{
     public:
          clsBot03(string strInputSymbol); //do nothing, same as parent
          ~clsBot03();
          //UNIQUE PART FOR EACH BOT//
          void   Updater();  //Unique Individual Indicator Update Function to Run Indicator
          bool   blBuyLogic   (SIGNAL_LIST &signal); // unique buy  logic for each child bot
          bool   blSellLogic  (SIGNAL_LIST &signal); // unique sell logic for each child bot
          bool   blOpenAllowed (double new_entry_price);
          void   Breakeven();
          void   Trailing();
          void   CloseAll(string text = "EQUITY STOPPED OUT");
          void   CloseInReverseDirection();
          void   DayClose();
          //IMPORTANT : TO PUT ENTRY, SL, TP in each buy sell logic
          //UNIQUE PART FOR EACH BOT//
          
     protected:
          
     private:
         bool    blSNDDirection(int type);
         bool    blWithinBigSND(int type);
         bool    blWithinSND(int type);
         bool    blWithinStructure(int type);
         bool    blWithinRB(int type);
         bool    blWithinBOS();
         bool    blWithinFIBO(int type);
         bool    blWithinSeasonMonth(int type);
         bool    blWithinSession(int type);
         bool    blConsecTimingAllowed ();
         double  dblLotCalculate(void);
         void    MonitorConsec();
         void    MultiplyUnrealizedLossedReturn();
         int     intUMATrend();
         void    UMA_Monitoring();
         string  strAlertBuyIdentifier;
         string  strAlertSellIdentifier;
         bool    blCheckSymbolMatch(string symbol_1, string symbol_2, int direction_1, int direction_2);
         bool    blPrimaryBasketDisAllowed(int intCheckDirection);
         // timeframe use to guide for selection (which tf is being triggered)
         clsSND  *TRADING_SND;
         clsStructure *TRADING_STRUC;
         datetime dtLastConsecBarTime;
          
};

clsBot03::clsBot03(string strInputSymbol):clsMasterBot(strInputSymbol)
{
     this.intBotMagic = entry_magic_number; //NEED OVERRIDE MAGIC NUMBER
     this.strAlertBuyIdentifier = "";
     this.strAlertSellIdentifier = "";
     Print("Create Bot03 for ",this.strSymbol);
     SND_TF1 = new clsSND(this.strSymbol,SND_TIMEFRAME_1);
     SND_TF2 = new clsSND(this.strSymbol,SND_TIMEFRAME_2);
     SND_TF3 = new clsSND(this.strSymbol,SND_TIMEFRAME_3);
     SND_TF1.blEAMode = true;
     SND_TF2.blEAMode = true;
     SND_TF3.blEAMode = true;
     SND_TF1.blDrawMode = true;
     SND_TF1.blCommentMode = true;
     SND_TF1.blFreshMode = final_snd_mode == FRESH_MODE ? True : False;
     Alert("Final SND MODE is ",final_snd_mode);
     SND_TF1.sup_color = SND1_ColorSupport;
     SND_TF1.res_color = SND1_ColorResistance;
     SND_TF2.blDrawMode = true;
     SND_TF2.blCommentMode = false;
     SND_TF2.blFreshMode = final_snd_mode == FRESH_MODE ? True : False;
     SND_TF2.sup_color = SND2_ColorSupport;
     SND_TF2.res_color = SND2_ColorResistance;
     SND_TF3.blDrawMode = true;
     SND_TF3.blFreshMode = final_snd_mode == FRESH_MODE ? True : False;
     SND_TF3.blCommentMode = false;
     SND_TF3.sup_color = SND3_ColorSupport;
     SND_TF3.res_color = SND3_ColorResistance;
     
     //STRUCTURE CREATION
     STRUC = new clsStructure(this.strSymbol,STRUC_TIMEFRAME);
     STRUC.EA_MODE = true;
     
     //TOGGLE = new clsTOGGLE();
     SEASON = new clsSeason(this.strSymbol,SND_TIMEFRAME_3);
     
     //GSHEET
     //we use default settings
     GSHEET = new clsGsheet();
     //test print direction
     //GSHEET.Updater("EURUSD");
     
     //SESSION
     SESSION = new clsSession();
     
     //DAY COUNTER
     DAYCOUNTER = new clsMasterIndi(strSymbol,PERIOD_D1);
     
     //ENHANCER
     ENHANCER = new clsTradeEnhancer(strSymbol,PERIOD_M1);
     
}

clsBot03::~clsBot03()
{
     if(CheckPointer(SND_TF1) == POINTER_DYNAMIC) delete SND_TF1;
     if(CheckPointer(SND_TF2) == POINTER_DYNAMIC) delete SND_TF2; 
     if(CheckPointer(SND_TF3) == POINTER_DYNAMIC) delete SND_TF3; 
     //STRUCTURE
     if(CheckPointer(STRUC)   == POINTER_DYNAMIC) delete STRUC; 
     if(CheckPointer(SEASON)  == POINTER_DYNAMIC) delete SEASON;
     if(CheckPointer(GSHEET)  == POINTER_DYNAMIC) delete GSHEET;
     if(CheckPointer(SESSION) == POINTER_DYNAMIC) delete SESSION;
     if(CheckPointer(DAYCOUNTER) == POINTER_DYNAMIC) delete DAYCOUNTER;
     if(CheckPointer(ENHANCER) == POINTER_DYNAMIC) delete ENHANCER;
     
}

void clsBot03::CloseInReverseDirection()
{
    //if(SND_TF1.intFinalDirection == -1)
    if(blSNDDirection(2))
    {
         if(TRADE.intTotalBuyCount(strSymbol,intBotMagic) > 0)
         {
            TRADE_COMMAND BUY_CLOSE;
            BUY_CLOSE._action = MODE_TCLSE;
            BUY_CLOSE._symbol = this.strSymbol;
            BUY_CLOSE._order_type = 0;
            BUY_CLOSE._magic  = this.intBotMagic;
            TRADE.CloseTradeAction(BUY_CLOSE);
         }
    }
    //if(SND_TF1.intFinalDirection == 1)
    if(blSNDDirection(1))
    {
        if(TRADE.intTotalSellCount(strSymbol,intBotMagic) > 0)
        {
         //close all sell in direction buy
         TRADE_COMMAND SELL_CLOSE;
         SELL_CLOSE._action = MODE_TCLSE;
         SELL_CLOSE._symbol = this.strSymbol;
         SELL_CLOSE._order_type = 1;
         SELL_CLOSE._magic  = this.intBotMagic;
         TRADE.CloseTradeAction(SELL_CLOSE);
        }
    }
}

bool clsBot03::blWithinSession(int type)
{
    if(Use_Session_Filter)
    {
         if(type == 1)
         {
               if(SESSION.blNewYorkSession() && !SESSION.blLondonSession() && !SESSION.blTokyoSession())
               {
                    Print("New York Session");
                    if(NewYork_Session == LONG || NewYork_Session == NEUTRAL) return(true);
               }
               if(SESSION.blLondonSession() && !SESSION.blNewYorkSession() && !SESSION.blTokyoSession())
               {
                    Print("London Session");
                    if(London_Session == LONG || London_Session == NEUTRAL) return(true);
               }
               if(SESSION.blTokyoSession() && !SESSION.blNewYorkSession() && !SESSION.blLondonSession())
               {
                    Print("Tokyo Session");
                    if(Tokyo_Session == LONG || Tokyo_Session == NEUTRAL) return(true);
               }
         }
         if(type == 2)
         {
               if(SESSION.blNewYorkSession() && !SESSION.blLondonSession() && !SESSION.blTokyoSession())
               {
                    Print("New York Session");
                    if(NewYork_Session == SHORT || NewYork_Session == NEUTRAL) return(true);
               }
               if(SESSION.blLondonSession() && !SESSION.blNewYorkSession() && !SESSION.blTokyoSession())
               {
                    Print("London Session");
                    if(London_Session == SHORT || London_Session == NEUTRAL) return(true);
               }
               if(SESSION.blTokyoSession() && !SESSION.blNewYorkSession() && !SESSION.blLondonSession())
               {
                    Print("Tokyo Session");
                    if(Tokyo_Session == SHORT || Tokyo_Session == NEUTRAL) return(true);
               }
         }
         return(false);
    }
    return(true);
}

void clsBot03::UMA_Monitoring(void)
{
   if(intUMATrend() == 1)
   {
       if(TRADE.dblTotalSellProfit(this.strSymbol,this.intBotMagic) < 0)
       {
           //close all sell in UMA BUY
           TRADE_COMMAND SELL_CLOSE;
           SELL_CLOSE._action = MODE_TCLSE;
           SELL_CLOSE._symbol = this.strSymbol;
           SELL_CLOSE._order_type = 1;
           SELL_CLOSE._magic  = this.intBotMagic;
       }
   }
   
   if(intUMATrend() == 2)
   {
       if(TRADE.dblTotalBuyProfit(this.strSymbol,this.intBotMagic) < 0)
       {
           //close all buy in UMA Sell
           TRADE_COMMAND BUY_CLOSE;
           BUY_CLOSE._action = MODE_TCLSE;
           BUY_CLOSE._symbol = this.strSymbol;
           BUY_CLOSE._order_type = 0;
           BUY_CLOSE._magic  = this.intBotMagic;
           
       }
   }
}

int clsBot03::intUMATrend()
{
   double range_current = MathAbs(iHigh(this.strSymbol,PERIOD_MN1,0) - iLow(this.strSymbol,PERIOD_MN1,0));
   double range_prev    = MathAbs(iHigh(this.strSymbol,PERIOD_MN1,1) - iLow(this.strSymbol,PERIOD_MN1,1));
   
   if(range_current >= range_prev * 2)
   {
       //UMA Activity, we get the direction
       if(iClose(this.strSymbol,PERIOD_MN1,0) > iOpen(this.strSymbol,PERIOD_MN1,0))
       {
            return(1);
       }
       if(iClose(this.strSymbol,PERIOD_MN1,0) < iOpen(this.strSymbol,PERIOD_MN1,0))
       {
            return(-1);
       }
   } 
   return(0);
}

void clsBot03::Breakeven(void)
{
    TRADE.Updater();
    if(ArraySize(TRADE._terminal_trades)>0)
    {
       static TRADE_COMMAND check_trade;
       check_trade._action = MODE_TCHNG;
       check_trade._breakeven_mode = Breakeven_Mode == 1 ? 1 : 4;
       //Print("Pre-enter BE mode is ",check_trade._breakeven_mode);
       check_trade._breakeven_input = BreakEven_Input;
       check_trade._symbol = this.strSymbol;
       TRADE.BreakEven(check_trade);
    }
}

void clsBot03::Trailing(void)
{
    if(ArraySize(TRADE._terminal_trades))
    {
       TRADE_COMMAND check_trade;
       check_trade._action = MODE_TCHNG;
       check_trade._trailing_mode  = 3;
       check_trade._trailing_input = Trailing_Percent_Input;
       check_trade._symbol = this.strSymbol;
       TRADE.TrailTrade(check_trade);
    }
}

bool clsBot03::blConsecTimingAllowed ()
{
    if(InpUsHMinForConsecTrade)
    {  
          if(Hour() == InpHourConsec && Minute() == InpMinConsec)
          {
               return(true);
          } 
          return(false);
    }
    return(true);
}

void clsBot03::MultiplyUnrealizedLossedReturn()
{
    if(money_management_mode != YOAV_MODE)
    {
       if(InpMultFloatLossReturn == 0) return;
       //get basket
       double sum_win  = TRADE.dblTotalWinningProfit(this.strSymbol,this.intBotMagic);
       double sum_loss = TRADE.dblTotalLossingProfit(this.strSymbol,this.intBotMagic);
       
       if(
            sum_win != 0 && sum_loss != 0 && sum_loss < 0 &&
            MathAbs(sum_loss) * InpMultFloatLossReturn  <= sum_win
         )
       {
            TRADE_COMMAND BUY_CLOSE;
              BUY_CLOSE._action = MODE_TCLSE;
              BUY_CLOSE._symbol = this.strSymbol;
              BUY_CLOSE._order_type = 0;
              BUY_CLOSE._magic  = this.intBotMagic;
              
              
              TRADE_COMMAND SELL_CLOSE;
              SELL_CLOSE._action = MODE_TCLSE;
              SELL_CLOSE._symbol = this.strSymbol;
              SELL_CLOSE._order_type = 1;
              SELL_CLOSE._magic  = this.intBotMagic;
              
              
              if(InpLYLSpecialMode)
              {
                 TRADE.CloseTrade(BUY_CLOSE);
                 TRADE.CloseTrade(SELL_CLOSE);
              }
              else
              {
                 TRADE.CloseTradeAction(BUY_CLOSE);
                 TRADE.CloseTradeAction(SELL_CLOSE);
              }
       }  
    }
    else
    {
       BASKET basket[];
       TRADE.YoavGetBasketTag(basket);
       for(int i = 0; i < ArraySize(basket); i++)
       {
           //Print("Checking basket of ",i);
           double sum_win  = TRADE.dblTotalWinningProfitByTag(this.strSymbol,this.intBotMagic,basket[i]._identifier);
           double sum_loss = TRADE.dblTotalLossingProfitByTag(this.strSymbol,this.intBotMagic,basket[i]._identifier);
           
           if(
               sum_win != 0 && sum_loss != 0 &&
               MathAbs(sum_loss) * InpMultFloatLossReturn  <= sum_win
            )
          {
              Print("Sum Win is ",sum_win, " with tag of ",basket[i]._identifier);
              Print("Sum Loss is ",sum_loss, " with tag of ",basket[i]._identifier);
              Print("[MULTIPLY UNREALIZED LOSSED RETURN] Preparing to close Basket ",basket[i]._identifier);
              TRADE_COMMAND BUY_CLOSE;
              BUY_CLOSE._action = MODE_TCLSE;
              BUY_CLOSE._symbol = this.strSymbol;
              BUY_CLOSE._order_type = 0;
              BUY_CLOSE._magic  = this.intBotMagic;
              BUY_CLOSE._yoav_source = basket[i]._identifier;
              
              TRADE_COMMAND SELL_CLOSE;
              SELL_CLOSE._action = MODE_TCLSE;
              SELL_CLOSE._symbol = this.strSymbol;
              SELL_CLOSE._order_type = 1;
              SELL_CLOSE._magic  = this.intBotMagic;
              SELL_CLOSE._yoav_source = basket[i]._identifier;
              
              if(InpLYLSpecialMode)
              {
                 TRADE.CloseTrade(BUY_CLOSE);
                 TRADE.CloseTrade(SELL_CLOSE);
              }
              else
              {
                 TRADE.CloseTradeAction(BUY_CLOSE);
                 TRADE.CloseTradeAction(SELL_CLOSE);
              }
          }
       }
    }
    
}

void clsBot03::Updater()
{
    ENHANCER.Updater();
    if(MM.blPseudoMarginStoppedOut(this.strSymbol))
    {
         Alert(this.strSymbol+" Being Stopped Out, Preparing to Close Trade ");
         this.CloseAll();
         ExpertRemove();
    }
    if(equity_cut_percent != 0 && MM.blPseudoEquityCut(equity_cut_percent))
    {
         Alert(this.strSymbol+" Equity Cut, Preparing to Close Trade ");
         this.CloseAll();
         //ExpertRemove();
    }
    if(!IsTesting()){GSHEET.Updater(this.strSymbol);}
    if(GSHEET.intDirection == 444) return;
    //CloseTrade(TRADE);
    if(!Use_MM)
    {
      if(Use_BreakEven) this.Breakeven();
      if(Use_Trailing)  this.Trailing();
    }
    
    
    if(SND_TF3.blNewBar()) 
    {   
       SND_TF3.Updater(TimeCurrent());
       //STRUC.Updater(TimeCurrent());
       SND_TF1.DrawLevel();
       SND_TF2.DrawLevel();
    }
    if(SND_TF1.blNewBar()) SND_TF1.Updater(TimeCurrent());
    if(SND_TF2.blNewBar()) SND_TF2.Updater(TimeCurrent());
    
    if(STRUC.blNewBar())
    {
       STRUC.Updater(TimeCurrent());
    }
    
    //SND_TF1.FinalDirectionCheck();
    //SND_TF2.FinalDirectionCheck();
    
    if(Use_MM && money_management_mode == YOAV_MODE)
    {
       datetime latest_consec_time = iTime(this.strSymbol,InpConsecBarTF,0);
       if(this.blConsecTimingAllowed() && this.dtLastConsecBarTime != latest_consec_time)
       {
            //Print("Latest Time is ",latest_consec_time);
            //Print("Last Saved Time is ",this.dtLastConsecBarTime);
            this.dtLastConsecBarTime = iTime(this.strSymbol,InpConsecBarTF,0);
            this.MonitorConsec();
       }
    }
    this.MultiplyUnrealizedLossedReturn();
    //this.UMA_Monitoring();    
    //bool long_allowed  = SND_TF1.intCurrentDirection(0) == -1 || blPrimaryBasketDisAllowed(1) ? false : true;
    //bool short_allowed = SND_TF1.intCurrentDirection(0) ==  1 || blPrimaryBasketDisAllowed(2) ? false : true;
    //bool long_allowed  = true;
    //bool short_allowed = true;
    //bool session = SESSION.blCheckSession("06:00","17:00");
    //bool session = SESSION.blCheckSession("06:00","23:00");
    bool session = SESSION.blLondonSession();// && SESSION.blNewYorkSession();
    bool long_allowed = ENHANCER.blOverZone(); //ENHANCER.blNonHighVolatilityZone();// && ENHANCER.blOverZone() && ENHANCER.blNonSRZone(1);// && //session;
    bool short_allowed = ENHANCER.blOverZone();//ENHANCER.blNonHighVolatilityZone();//&& ENHANCER.blOverZone() && ENHANCER.blNonSRZone(2);//&& //session;
    TRADE.MonitorSlTp(long_allowed,short_allowed);
    DayClose();
    /*
    string column = "Date;Equities;";
    string data   = (string)TimeCurrent()+";"+(string)AccountEquity()+";";
    READ.WriteData("EQUITIES.CSV",column,data);
    */
    //CloseInReverseDirection();
    
}

double clsBot03::dblLotCalculate(void)
{
    double lot_value = fix_lot_size;
    if(LotSizePer2000>0) {
         lot_value = MathMax(NormalizeDouble((int)(MM.dblPseudoAccountBalance(strSymbol)/2000)*LotSizePer2000,2),0.01);
    }
    else
    {
         lot_value = fix_lot_size;
    }
    return(lot_value);
}


void clsBot03::DayClose()
{
   if( Use_DayClose && 
       (DAYCOUNTER.blNewBar() || SESSION.blFridayClose())
     ) 
    {
      CloseAll("DAILY CLOSE");
    }
}

bool clsBot03::blCheckSymbolMatch(string symbol_1, string symbol_2, int direction_1, int direction_2)
{
    //to check whether the both symbol is in the same trading direction, if yes return true
    //MODIFY THE STRING FIRST
    /*
    if(InpSymbolPrefix != "" && StringFind(symbol_1,InpSymbolPrefix,0) >= 0)
    {
        StringReplace(symbol_1,InpSymbolPrefix,"");
    }
    if(InpSymbolSuffix != "" && StringFind(symbol_1,InpSymbolSuffix,0) >= 0)
    {
        StringReplace(symbol_1,InpSymbolSuffix,"");
    }
    if(InpSymbolPrefix != "" && StringFind(symbol_2,InpSymbolPrefix,0) >= 0)
    {
        StringReplace(symbol_2,InpSymbolPrefix,"");
    }
    if(InpSymbolSuffix != "" && StringFind(symbol_2,InpSymbolSuffix,0) >= 0)
    {
        StringReplace(symbol_2,InpSymbolSuffix,"");
    }
    */
    string pair_1 = StringSubstr(symbol_1,0,3);
    string base_1 = StringSubstr(symbol_1,3,3);
    string pair_2 = StringSubstr(symbol_2,0,3);
    string base_2 = StringSubstr(symbol_2,3,3);
    
    if(direction_1 == direction_2)
    {
         if(
              pair_1 == pair_2 ||
              base_1 == base_2
           )
         {
             return(true);
         }
    }
    
    if(direction_1 != direction_2)
    {
        if(
             pair_1 == base_2 ||
             pair_2 == base_1
          )
        {
            return(true);
        }
    }
    
    return(false);
}

bool clsBot03::blPrimaryBasketDisAllowed(int intCheckDirection)
{ 
    if(BasketPrimaryAlertCount == 0) return(false);
    //1 is for LONG, 2 is for SHORT
    intCheckDirection = intCheckDirection - 1;
    //get basket
    BASKET basket[];
    TRADE.YoavGetBasketTag(basket,2);
    BASKET primary_basket_list[]; //basket list that each trade is full
    int ori_basket_size = ArraySize(basket);
    
    //STEP 1 : CHECK AND FILL UP PRIMARY BASKET WHICH IS FULL
    int primary_basket_size = 0;
    if(ori_basket_size > 0)
    {
         for(int i = 0; i < ori_basket_size; i++)
         {
             //get trade number by basket
             int trade_number = TRADE.intTotalTradeNumberByTag(basket[i]._symbol,intBotMagic,basket[i]._identifier,2);
             if(trade_number >= BasketPrimaryAlertCount)
             {
                 primary_basket_size = ArraySize(primary_basket_list);
                 ArrayResize(primary_basket_list,primary_basket_size+1);
                 primary_basket_list[primary_basket_size] =  basket[i];
             }
         }
    }
    
    if(primary_basket_size == 0) {return(false);} //we allow for trading
    else
    {  
        for(int i = 0; i < primary_basket_size; i++)
        {
            if(primary_basket_list[i]._symbol != this.strSymbol)
            {
                //Check same group or not
                if(this.blCheckSymbolMatch(primary_basket_list[i]._symbol,this.strSymbol,primary_basket_list[i]._direction,intCheckDirection))
                {
                    //WE LIMIT TRADING
                    string comment = "Same Direction Primary Basket Exist, Trading Disabled"; 
                    return(true);
                }
            }
            else
            {
                //self is the primary symbol, we close other trades
                //this.PrimaryBasketCloseSameDirection(primary_basket_list[i]);
            }
             
        }
    }
    
    return(false);
}

void clsBot03::CloseAll(string text = "EQUITY STOPPED OUT")
{
     Alert("["+this.strSymbol+" "+text+"] Preparing to close all trads ");
     TRADE_COMMAND BUY_CLOSE;
     BUY_CLOSE._action = MODE_TCLSE;
     BUY_CLOSE._symbol = this.strSymbol;
     BUY_CLOSE._order_type = 0;
     BUY_CLOSE._magic  = this.intBotMagic;
     
     TRADE_COMMAND SELL_CLOSE;
     SELL_CLOSE._action = MODE_TCLSE;
     SELL_CLOSE._symbol = this.strSymbol;
     SELL_CLOSE._order_type = 1;
     SELL_CLOSE._magic  = this.intBotMagic;
     
     TRADE.CloseTradeAction(BUY_CLOSE);
     TRADE.CloseTradeAction(SELL_CLOSE);
}

void clsBot03::MonitorConsec(void)
{
    //bool long_allowed  = this.blPrimaryBasketDisAllowed(1) == false ? true : false;
    //bool short_allowed = this.blPrimaryBasketDisAllowed(2) == false ? true : false;
    if(!TRADE.MonitorYoav(true,true))
    {
      if(TRADE.intTotalBuyCount(this.strSymbol,this.intBotMagic) > 0 || TRADE.intTotalBuyCount(this.strSymbol,this.intBotMagic) > 0) 
      {
         string comment = "Consec entry price too close. Waiting for new bar";
         //this.PrintLog(comment);
      }
    }
}


bool clsBot03::blWithinSeasonMonth(int type)
{
    if(use_season_month)
    {
        if(SEASON.blSeasonMonthAllowed(TimeCurrent(),type))
        {
           return(true);
        }
        return(false);
    } 
    return(true);
}


bool clsBot03::blSNDDirection(int type)
{
    //SND_MODE mode = snd_selection == 1 ? input_snd_mode : FreshZoneOnly ? 2 : 1;
    if(use_snd_direction)
    {
       if(type == 1)
       {
            if(SND_TF1.intCurrentDirection(0,final_snd_mode) == 1 &&
               SND_TF1.intCurrentDirection(0,final_snd_mode) == 1
              )
            {
                return(true);
            }
       }
       if(type == 2)
       {
            if(SND_TF1.intCurrentDirection(0,final_snd_mode) == -1 &&
               SND_TF1.intCurrentDirection(0,final_snd_mode) == -1
              )
            {
                return(true);
            }
       }
       return(false);
    }
    return(true);
}

bool clsBot03::blWithinStructure(int type)
{
   if(use_struc)
   {
      if(ArraySize(STRUC.intTrendArray) > 1)
      {
         if(type == 1)
         {
             if(STRUC.intTrend == 0 && STRUC.intTrendArray[1] == 2)
             {
                 if(!use_fibo) return(true);
                 else
                 {
                     int bos_idx = STRUC.BOS._BOS_index;
                     FIBO = new clsFibo(this.strSymbol,STRUC.intPeriod);
                     FIBO.EA_MODE = true;
                     FIBO.intFiboLookBack = bos_idx;
                     FIBO.Updater(TimeCurrent());
                     double fib_up = 0; double fib_dn = 0;
                     if(FIBO_UP == FIBO000) fib_up = FIBO.CUR_FIBO._FIBO000Value;
                     if(FIBO_UP == FIBO236) fib_up = FIBO.CUR_FIBO._FIBO236Value;
                     if(FIBO_UP == FIBO382) fib_up = FIBO.CUR_FIBO._FIBO382Value;
                     if(FIBO_UP == FIBO500) fib_up = FIBO.CUR_FIBO._FIBO500Value;
                     if(FIBO_UP == FIBO618) fib_up = FIBO.CUR_FIBO._FIBO618Value;
                     if(FIBO_UP == FIBO702) fib_up = FIBO.CUR_FIBO._FIBO702Value;
                     if(FIBO_UP == FIBO786) fib_up = FIBO.CUR_FIBO._FIBO786Value;
                     if(FIBO_UP == FIBO100) fib_up = FIBO.CUR_FIBO._FIBO100Value;
                     
                     if(FIBO_DN == FIBO000) fib_dn = FIBO.CUR_FIBO._FIBO000Value;
                     if(FIBO_DN == FIBO236) fib_dn = FIBO.CUR_FIBO._FIBO236Value;
                     if(FIBO_DN == FIBO382) fib_dn = FIBO.CUR_FIBO._FIBO382Value;
                     if(FIBO_DN == FIBO500) fib_dn = FIBO.CUR_FIBO._FIBO500Value;
                     if(FIBO_DN == FIBO618) fib_dn = FIBO.CUR_FIBO._FIBO618Value;
                     if(FIBO_DN == FIBO702) fib_dn = FIBO.CUR_FIBO._FIBO702Value;
                     if(FIBO_DN == FIBO786) fib_dn = FIBO.CUR_FIBO._FIBO786Value;
                     if(FIBO_DN == FIBO100) fib_dn = FIBO.CUR_FIBO._FIBO100Value;
                     
                     if (FIBO.CUR_FIBO._active == 1 &&
                         MarketInfo(this.strSymbol,MODE_ASK) >= fib_dn  &&
                         MarketInfo(this.strSymbol,MODE_ASK) <= fib_up 
                        )
                        {
                            return(true);
                        }
                     
                 }
             }
             else
             {
                 if(CheckPointer(FIBO)==POINTER_DYNAMIC) delete FIBO;
             }
         }
         if(type == 2)
         {
             if(STRUC.intTrend == 0 && STRUC.intTrendArray[1] == 1)
             {
                 if(!use_fibo) return(true);
                 else
                 {
                     int bos_idx = STRUC.BOS._BOS_index;
                     FIBO = new clsFibo(this.strSymbol,STRUC.intPeriod);
                     FIBO.EA_MODE = true;
                     FIBO.intFiboLookBack = bos_idx;
                     FIBO.Updater(TimeCurrent());
                     double fib_up = 0; double fib_dn = 0;
                     if(FIBO_UP == FIBO000) fib_up = FIBO.CUR_FIBO._FIBO000Value;
                     if(FIBO_UP == FIBO236) fib_up = FIBO.CUR_FIBO._FIBO236Value;
                     if(FIBO_UP == FIBO382) fib_up = FIBO.CUR_FIBO._FIBO382Value;
                     if(FIBO_UP == FIBO500) fib_up = FIBO.CUR_FIBO._FIBO500Value;
                     if(FIBO_UP == FIBO618) fib_up = FIBO.CUR_FIBO._FIBO618Value;
                     if(FIBO_UP == FIBO702) fib_up = FIBO.CUR_FIBO._FIBO702Value;
                     if(FIBO_UP == FIBO786) fib_up = FIBO.CUR_FIBO._FIBO786Value;
                     if(FIBO_UP == FIBO100) fib_up = FIBO.CUR_FIBO._FIBO100Value;
                     
                     if(FIBO_DN == FIBO000) fib_dn = FIBO.CUR_FIBO._FIBO000Value;
                     if(FIBO_DN == FIBO236) fib_dn = FIBO.CUR_FIBO._FIBO236Value;
                     if(FIBO_DN == FIBO382) fib_dn = FIBO.CUR_FIBO._FIBO382Value;
                     if(FIBO_DN == FIBO500) fib_dn = FIBO.CUR_FIBO._FIBO500Value;
                     if(FIBO_DN == FIBO618) fib_dn = FIBO.CUR_FIBO._FIBO618Value;
                     if(FIBO_DN == FIBO702) fib_dn = FIBO.CUR_FIBO._FIBO702Value;
                     if(FIBO_DN == FIBO786) fib_dn = FIBO.CUR_FIBO._FIBO786Value;
                     if(FIBO_DN == FIBO100) fib_dn = FIBO.CUR_FIBO._FIBO100Value;
                     if (FIBO.CUR_FIBO._active == 1 &&
                         MarketInfo(this.strSymbol,MODE_BID) <= fib_up  &&
                         MarketInfo(this.strSymbol,MODE_BID) >= fib_dn 
                        )
                      {
                           return(true);
                      }
                     
                 }
             }
             else
             {
                 if(CheckPointer(FIBO)==POINTER_DYNAMIC) delete FIBO;
             }
         }
      }
      
      return(false);
   }
   return(true);
}

bool clsBot03::blWithinRB(int type)
{
   if(use_rb)
   {
      CLevel res_level;
      CLevel sup_level;
      if(final_snd_mode == 1)
      {
           res_level = SND_TF3.latest_res_lvl;
           sup_level = SND_TF3.latest_sup_lvl;
      }
      if(final_snd_mode == 2)
      {
           res_level = SND_TF3.latest_fresh_res_lvl;
           sup_level = SND_TF3.latest_fresh_sup_lvl;
      }
      if(type == 1)
      {  
           for(int i = 0; i < ArraySize(sup_level.RoundNumber); i++)
           {
               if(MarketInfo(this.strSymbol,MODE_BID) == sup_level.RoundNumber[i])
               {
                   return(true);
               }
           }
      }
      if(type == 2)
      {  
           for(int i = 0; i < ArraySize(res_level.RoundNumber); i++)
           {
               if(MarketInfo(this.strSymbol,MODE_BID) == res_level.RoundNumber[i])
               {
                   return(true);
               }
           }
      }
      return(false);
   }
   return(true);
}


bool clsBot03::blWithinSND(int type)
{
   if(use_snd)
   {
      double tf3_sel_sup_up=0; double tf3_sel_sup_dn=0; double tf3_sel_res_up=0; double tf3_sel_res_dn=0;
      
      if(final_snd_mode == 1)
      {
           tf3_sel_sup_up = SND_TF3.sup_up; tf3_sel_sup_dn = SND_TF3.sup_dn; tf3_sel_res_up = SND_TF3.res_up; tf3_sel_res_dn = SND_TF3.res_dn;
           
      }
      if(final_snd_mode == 2)
      {
           tf3_sel_sup_up = SND_TF2.sup_up_fresh; tf3_sel_sup_dn = SND_TF2.sup_dn_fresh; tf3_sel_res_up = SND_TF2.res_up_fresh; tf3_sel_res_dn = SND_TF2.res_dn_fresh;
      }
      
     
      if(type == 1)
      {
          if(tf3_sel_sup_up != 0 && tf3_sel_sup_dn != 0 && 
            MarketInfo(this.strSymbol,MODE_ASK) < tf3_sel_sup_up && 
            MarketInfo(this.strSymbol,MODE_ASK) > tf3_sel_sup_dn
           )
           {
              // this.TRADING_SND = SND_TF3;
               return(true);
           }
      }
      if(type == 2)
      {
         //check for sell
         if(tf3_sel_res_up != 0 && tf3_sel_res_dn != 0 && 
            MarketInfo(this.strSymbol,MODE_BID) < tf3_sel_res_up && 
            MarketInfo(this.strSymbol,MODE_BID) > tf3_sel_res_dn
           )
           {
               //this.TRADING_SND = SND_TF3;
               return(true);
           }
      }
       
      return(false);
   }
   return(true);
}

bool clsBot03::blBuyLogic(SIGNAL_LIST &signal)
{
     //bool session = SESSION.blCheckSession("00:00","06:00");
     //bool session = SESSION.blLondonSession() && SESSION.blNewYorkSession();
     //if(!session) return(false);
     // 
     if(!ENHANCER.blOverZone()) return(false);
     //if(!ENHANCER.blOverZone() || !ENHANCER.blNonHighVolatilityZone() || ! ENHANCER.blNonSRZone(1)) return(false);
     if(MM.blPseudoMarginInsufficient(signal._symbol) || MM.blPseudoMarginStoppedOut(signal._symbol))
     {
         return(false);
     }
     if(intUMATrend() == -1) return(false);
     if(blPrimaryBasketDisAllowed(1)) return(false);
     //Print("BUY Current Time Allow to trade is ",bl_TimeAllowed());
     //Print("BUY STRUCT signal is ",this.blWithinStructure(1));
     //Print("Check Pointer Dynamic is ",CheckPointer(this.TRADING_SND) == POINTER_DYNAMIC);
     this.TRADING_SND = SND_TF2;
     //Alert("BUY SND TRADE Res Up is ",this.TRADING_SND.res_up);
     //Alert("BUY SND TRADE Res Dn is ",this.TRADING_SND.res_dn);
     if( 
         this.blSNDDirection(1) && 
         this.blWithinSND(1)  &&
         this.blWithinRB(1) && 
         this.blWithinStructure(1) &&
         //SESSION.blLondonSession() &&
         //this.blWithinStructure(2) &&
         //this.blWithinSeasonMonth(1) &&
         this.blWithinSession(1) &&
         GSHEET.intDirection != -1 && GSHEET.intDirection != 444 &&
         CheckPointer(this.TRADING_SND) == POINTER_DYNAMIC &&
         TRADING_SND.sup_dn != 0
       )
      {
          
         
         //alert identifier : TRADING_SND_res_up + TRADING_SND_res_dn + TRADING_SND_sup_up + TRADING_SND_sup_dn 
         string alert_identifier = (string)SND_TF1.res_up + (string)SND_TF1.res_dn + (string)SND_TF1.sup_up + (string)SND_TF1.sup_dn +
                                 (string)SND_TF2.res_up + (string)SND_TF2.res_dn + (string)SND_TF2.sup_up + (string)SND_TF2.sup_dn +
                                 (string)SND_TF3.res_up + (string)SND_TF3.res_dn + (string)SND_TF3.sup_up + (string)SND_TF3.sup_dn;
         //string alert_identifier = (string)STRUC.intTrend + (string)(int)STRUC.dblTrendHigh + (string)STRUC.intTrendHighIdx + (string)(int)STRUC.dblTrendLow + (string)STRUC.intTrendLowIdx;
         
         if (this.strAlertBuyIdentifier !=  alert_identifier)
         {
              
              Alert("[EUPORIAFIX ALERT] : Buy Opportunity Present at ",this.strSymbol);
              
              this.strAlertBuyIdentifier =  alert_identifier;
              double ask = MarketInfo(this.strSymbol,MODE_ASK);
               signal._symbol  = this.strSymbol;
               signal._entry   = ask;
               //signal._sl      = signal._entry - sl_x_pip * pips(this.strSymbol);
               signal._sl      = this.TRADING_SND.sup_dn - sl_x_pip * pips(this.strSymbol);
               double sl_point = signal._entry - signal._sl;
               double sl_pip   = sl_point / pips(this.strSymbol);
               //if(sl_pip == 0 || sl_pip > 30) return(false);
               signal._lot     = Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,this.strSymbol,sl_pip) :MM.dblLotSizePerRisk(this.strSymbol,sl_pip);
               if(Use_Compound_Lots) signal._lot = dblLotCalculate();
               signal._tp      = signal._entry + RR_Ratio * sl_point;
               signal._magic = this.intBotMagic;
               Alert("Buy Signal Present");
               return(true);
         }     
         
                 
         
         
      }
     return(false);
}

bool clsBot03::blSellLogic(SIGNAL_LIST &signal)
{
     //bool session = SESSION.blCheckSession("00:00","06:00");
     //bool session = SESSION.blLondonSession() && SESSION.blNewYorkSession();
     //if(!session) return(false);
     //
     if(!ENHANCER.blOverZone()) return(false);
     //if(!ENHANCER.blOverZone() || !ENHANCER.blNonHighVolatilityZone() || !ENHANCER.blNonSRZone(2)) return(false);
     if(MM.blPseudoMarginInsufficient(signal._symbol) || MM.blPseudoMarginStoppedOut(signal._symbol))
     {
         return(false);
     }
     if(intUMATrend() == 1) return(false);
     if(blPrimaryBasketDisAllowed(1)) return(false);
     //Print("SELL Current Time Allow to trade is ",bl_TimeAllowed());
     this.TRADING_SND = SND_TF2;
     if( 
         this.blSNDDirection(2) && 
         this.blWithinSND(2)  &&
         this.blWithinRB(2) && 
         this.blWithinStructure(2) &&
         //SESSION.blLondonSession() &&
         //this.blWithinStructure(1) &&
         //this.blWithinSeasonMonth(2) &&
         GSHEET.intDirection != -1 && GSHEET.intDirection != 444 &&
         this.blWithinSession(2) &&
         GSHEET.intDirection != 1 &&
         CheckPointer(this.TRADING_SND) == POINTER_DYNAMIC &&
         TRADING_SND.res_up != 0
       )
      {
         
         
         //long alert_identifier = (int)this.TRADING_SND.res_up + (int)this.TRADING_SND.res_dn + (int)this.TRADING_SND.sup_up + (int)this.TRADING_SND.sup_dn;
         string alert_identifier = (string)SND_TF1.res_up + (string)SND_TF1.res_dn + (string)SND_TF1.sup_up + (string)SND_TF1.sup_dn +
                                 (string)SND_TF2.res_up + (string)SND_TF2.res_dn + (string)SND_TF2.sup_up + (string)SND_TF2.sup_dn +
                                 (string)SND_TF3.res_up + (string)SND_TF3.res_dn + (string)SND_TF3.sup_up + (string)SND_TF3.sup_dn;
         if (this.strAlertSellIdentifier !=  alert_identifier)
         {
              Alert("[EUPORIAFIX ALERT] : Sell Opportunity Present at ",this.strSymbol);
              
              this.strAlertSellIdentifier =  alert_identifier;
              double bid = MarketInfo(this.strSymbol,MODE_BID);
              signal._symbol  = this.strSymbol;
              signal._entry   = bid;
              //signal._sl      = signal._entry + sl_x_pip * pips(this.strSymbol);
              signal._sl      = this.TRADING_SND.res_up + sl_x_pip * pips(this.strSymbol);
              double sl_point = signal._sl - signal._entry;
              double sl_pip   = sl_point / pips(this.strSymbol);
              //if(sl_pip == 0 || sl_pip > 30) return(false);
              signal._lot     = Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,this.strSymbol,sl_pip) :MM.dblLotSizePerRisk(this.strSymbol,sl_pip);
              if(Use_Compound_Lots) signal._lot = dblLotCalculate();
              signal._tp      = signal._entry - RR_Ratio * sl_point;
              signal._magic = this.intBotMagic;
              Print("Sell Signal Present");
              return(true);  
         } 
         
         
         
      }
     return(false);
}