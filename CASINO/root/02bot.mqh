#include "/MASTER_BOT.mqh"
#include "/SND_OPTIMIZED.mqh"
input color SND2_ColorSupport = clrAqua;   // SND TF 2 Support Color
input color SND2_ColorResistance = clrPurple; // SND TF 2 Resistance Color
input color SND3_ColorSupport = clrGreenYellow;   // SND TF 3 Support Color
input color SND3_ColorResistance = clrMagenta; // SND TF 3 Resistance Color
#include "/FIBO.mqh"
// BOT O2 : USING THE 5 TIMEFRAME TO EQUATE + FIBO 

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
extern bool take_trade_inside_big_snd = True;
extern SND_SELECTION_MODE snd_selection = 1; 
extern SND_MODE input_snd_mode = 1; 
SND_MODE final_snd_mode = snd_selection == 1 ? input_snd_mode : FreshZoneOnly ? (SND_MODE)2 : (SND_MODE)1;

extern period TIMEFRAME_1 = MN1;
extern period TIMEFRAME_2 = H4;
extern period TIMEFRAME_3 = M15;
extern period TIMEFRAME_4 = M5;
extern period TIMEFRAME_5 = M1;
extern string _tmp5_ = "===== STRATEGY INPUT =====";
extern int  entry_magic_number = 98765;
extern bool use_timing = true;
extern bool use_base = true;
extern bool use_confirmation_1 = true;
extern bool use_confirmation_2 = true;
extern int  x_bar_distance = 0;
extern int  sl_x_pip = 20; 
extern double RR_Ratio = 10;
extern string _tmp6_ = "===== BREAKEVEN SETTINGS =====";
extern bool   Use_BreakEven = true;
extern BE_MODE Breakeven_Mode = 1; 
extern double BreakEven_Input = 30;
extern string _tmp7_ = "===== TRAILING SETTINGS =====";
extern bool   Use_Trailing = true;
extern double Trailing_Percent_Input = 3;
string trade_comment = "EUPORIAFX";
clsSND *SND_TF1;
clsSND *SND_TF2;
clsSND *SND_TF3;
//clsSND *SND_TF4;
//clsSND *SND_TF5;
clsStructure *STRUC_TF3;
clsStructure *STRUC_TF4;
clsStructure *STRUC_TF5;
//clsTOGGLE *TOGGLE;

void OnChartEvent(const int id,  const long &lparam, const double &dparam,  const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
   {    
   
      if(sparam==SND_TF1.strToggleName || sparam==SND_TF2.strToggleName || sparam==SND_TF3.strToggleName)
      {
            ToggleSession = true;
            FreshZoneOnly = FreshZoneOnly != false ? false : true;
            //Alert("HELLO");  
            SND_TF1.Updater(TimeCurrent());
            SND_TF2.Updater(TimeCurrent());
            SND_TF3.Updater(TimeCurrent());
      }
      
   }
}



class clsBot02 : 
     public  clsMasterBot
{
     public:
          clsBot02(string strInputSymbol); //do nothing, same as parent
          ~clsBot02();
          //UNIQUE PART FOR EACH BOT//
          void   Updater();  //Unique Individual Indicator Update Function to Run Indicator
          bool   blBuyLogic   (SIGNAL_LIST &signal); // unique buy  logic for each child bot
          bool   blSellLogic  (SIGNAL_LIST &signal); // unique sell logic for each child bot
          bool   blOpenAllowed (double new_entry_price);
          //bool   blCloseAllowed(int intInputType, double dblInputCheckPrice, clsTradeClass &TRADE);
          //void   CloseTrade(clsTradeClass &TRADE);
          void   Breakeven();
          void   Trailing();
          //IMPORTANT : TO PUT ENTRY, SL, TP in each buy sell logic
          //UNIQUE PART FOR EACH BOT//
          
     protected:
          
     private:
         bool    blSNDDirection(int type);
         bool    blWithinBigSND(int type);
         bool    blWithinSND(int type);
         bool    blWithinBOS();
         bool    blWithinFIBO(int type);
         long    longAlertIdentifier;
         // timeframe use to guide for selection (which tf is being triggered)
         clsSND  *TRADING_SND;
         clsStructure *TRADING_STRUC;
          
};

clsBot02::clsBot02(string strInputSymbol):clsMasterBot(strInputSymbol)
{
     this.intBotMagic = entry_magic_number; //NEED OVERRIDE MAGIC NUMBER
     Print("Create Bot02 for ",this.strSymbol);
     SND_TF1 = new clsSND(this.strSymbol,TIMEFRAME_1);
     SND_TF2 = new clsSND(this.strSymbol,TIMEFRAME_2);
     SND_TF3 = new clsSND(this.strSymbol,TIMEFRAME_3);
     //SND_TF4 = new clsSND(this.strSymbol,TIMEFRAME_4);
     //SND_TF5 = new clsSND(this.strSymbol,TIMEFRAME_5);
     SND_TF1.blDrawMode = true;
     SND_TF1.blCommentMode = true;
     SND_TF1.sup_color = SND1_ColorSupport;
     SND_TF1.res_color = SND1_ColorResistance;
     SND_TF2.blDrawMode = true;
     SND_TF2.blCommentMode = false;
     SND_TF2.sup_color = SND2_ColorSupport;
     SND_TF2.res_color = SND2_ColorResistance;
     SND_TF3.blDrawMode = true;
     SND_TF3.blCommentMode = false;
     SND_TF3.sup_color = SND3_ColorSupport;
     SND_TF3.res_color = SND3_ColorResistance;
     //SND_TF4.blDrawMode = false;
     //SND_TF4.blCommentMode = false;
     //SND_TF5.blDrawMode = false;
     //SND_TF5.blCommentMode = false;
     //STRUCTURE CREATION
     STRUC_TF3 = new clsStructure(this.strSymbol,TIMEFRAME_3);
     STRUC_TF4 = new clsStructure(this.strSymbol,TIMEFRAME_4);
     STRUC_TF5 = new clsStructure(this.strSymbol,TIMEFRAME_5);
     STRUC_TF3.EA_MODE = true;
     STRUC_TF4.EA_MODE = true;
     STRUC_TF5.EA_MODE = true;
     //this.TRADE = new clsTradeClass();
     
     //TOGGLE = new clsTOGGLE();
}

clsBot02::~clsBot02()
{
     if(CheckPointer(SND_TF1) == POINTER_DYNAMIC) delete SND_TF1;
     if(CheckPointer(SND_TF2) == POINTER_DYNAMIC) delete SND_TF2; 
     if(CheckPointer(SND_TF3) == POINTER_DYNAMIC) delete SND_TF3; 
     //if(CheckPointer(SND_TF4) == POINTER_DYNAMIC) delete SND_TF4; 
     //if(CheckPointer(SND_TF5) == POINTER_DYNAMIC) delete SND_TF5; 
     
     //STRUCTURE
     if(CheckPointer(STRUC_TF3) == POINTER_DYNAMIC) delete STRUC_TF3; 
     if(CheckPointer(STRUC_TF4) == POINTER_DYNAMIC) delete STRUC_TF4; 
     if(CheckPointer(STRUC_TF5) == POINTER_DYNAMIC) delete STRUC_TF5;
     
     //END REFERENCE POINTER
     if(CheckPointer(TRADING_SND) == POINTER_DYNAMIC) delete TRADING_SND;
     if(CheckPointer(TRADING_STRUC) == POINTER_DYNAMIC) delete TRADING_STRUC;
     
     //if(CheckPointer(TOGGLE) == POINTER_DYNAMIC) delete TOGGLE;
}

void clsBot02::Updater()
{
    //CloseTrade(TRADE);
    if(Use_BreakEven) this.Breakeven();
    //if(Use_Trailing)  this.Trailing();
    if(SND_TF2.blNewBar()) SND_TF2.Updater(TimeCurrent());
    if(SND_TF3.blNewBar()) SND_TF3.Updater(TimeCurrent());
    if(SND_TF1.blNewBar()) SND_TF1.Updater(TimeCurrent());
    //if(SND_TF4.blNewBar()) SND_TF4.Updater(TimeCurrent());
    //if(SND_TF5.blNewBar()) SND_TF5.Updater(TimeCurrent());
    
    //STRUCTURE
    if(STRUC_TF3.blNewBar()) STRUC_TF3.Updater(TimeCurrent());
    if(STRUC_TF4.blNewBar()) STRUC_TF4.Updater(TimeCurrent());
    if(STRUC_TF5.blNewBar()) 
    {
       //we update SND draw as well
       //Print("Update SND Draw level");
       SND_TF1.DrawLevel();
       SND_TF2.DrawLevel();
       SND_TF3.DrawLevel();
       STRUC_TF5.Updater(TimeCurrent());
    }
    
}

bool clsBot02::blSNDDirection(int type)
{
    //SND_MODE mode = snd_selection == 1 ? input_snd_mode : FreshZoneOnly ? 2 : 1;
    if(type == 1)
    {
         if(SND_TF1.intCurrentDirection(0, final_snd_mode) == 1)
         {
             return(true);
         }
    }
    if(type == 2)
    {
         if(SND_TF1.intCurrentDirection(0, final_snd_mode) == -1)
         {
             return(true);
         }
    }
    return(false);
}

bool clsBot02::blWithinBigSND(int type)
{
   double tf1_sel_sup_up=0; double tf1_sel_sup_dn=0; double tf1_sel_res_up=0; double tf1_sel_res_dn=0;
   double tf2_sel_sup_up=0; double tf2_sel_sup_dn=0; double tf2_sel_res_up=0; double tf2_sel_res_dn=0;
   double tf3_sel_sup_up=0; double tf3_sel_sup_dn=0; double tf3_sel_res_up=0; double tf3_sel_res_dn=0;
   
   if(final_snd_mode == 1)
   {
        tf1_sel_sup_up = SND_TF1.sup_up; tf1_sel_sup_dn = SND_TF1.sup_dn; tf1_sel_res_up = SND_TF1.res_up; tf1_sel_res_dn = SND_TF1.res_dn;
        tf2_sel_sup_up = SND_TF2.sup_up; tf2_sel_sup_dn = SND_TF2.sup_dn; tf2_sel_res_up = SND_TF2.res_up; tf2_sel_res_dn = SND_TF2.res_dn;
        tf3_sel_sup_up = SND_TF3.sup_up; tf3_sel_sup_dn = SND_TF3.sup_dn; tf3_sel_res_up = SND_TF3.res_up; tf3_sel_res_dn = SND_TF3.res_dn;
        
   }
   if(final_snd_mode == 2)
   {
        tf1_sel_sup_up = SND_TF1.sup_up_fresh; tf1_sel_sup_dn = SND_TF1.sup_dn_fresh; tf1_sel_res_up = SND_TF1.res_up_fresh; tf1_sel_res_dn = SND_TF1.res_dn_fresh;
        tf2_sel_sup_up = SND_TF2.sup_up_fresh; tf2_sel_sup_dn = SND_TF2.sup_dn_fresh; tf2_sel_res_up = SND_TF2.res_up_fresh; tf2_sel_res_dn = SND_TF2.res_dn_fresh;
        tf3_sel_sup_up = SND_TF3.sup_up_fresh; tf3_sel_sup_dn = SND_TF3.sup_dn_fresh; tf3_sel_res_up = SND_TF3.res_up_fresh; tf3_sel_res_dn = SND_TF3.res_dn_fresh;
   }
   if(take_trade_inside_big_snd)
   {
      if (type == 1)
      {
           if (tf2_sel_sup_up <= tf1_sel_sup_up && tf2_sel_sup_dn >= tf1_sel_sup_dn)
           {
                return (true);
           }
           if (tf3_sel_sup_up <= tf1_sel_sup_up && tf3_sel_sup_dn >= tf1_sel_sup_dn)
           {
                return (true);
           }
      }
      if (type == 2)
      {
           if (tf2_sel_res_up <= tf1_sel_res_up && tf2_sel_res_dn >= tf1_sel_res_dn)
           {
                return (true);
           }
           if (tf3_sel_res_up <= tf1_sel_res_up && tf3_sel_res_dn >= tf1_sel_res_dn)
           {
                return (true);
           }
      }
      return (false);
   }
   return (true);
}

bool clsBot02::blWithinSND(int type)
{
   double tf1_sel_sup_up=0; double tf1_sel_sup_dn=0; double tf1_sel_res_up=0; double tf1_sel_res_dn=0;
   double tf2_sel_sup_up=0; double tf2_sel_sup_dn=0; double tf2_sel_res_up=0; double tf2_sel_res_dn=0;
   double tf3_sel_sup_up=0; double tf3_sel_sup_dn=0; double tf3_sel_res_up=0; double tf3_sel_res_dn=0;
   if(final_snd_mode == 1)
   {
        tf1_sel_sup_up = SND_TF1.sup_up; tf1_sel_sup_dn = SND_TF1.sup_dn; tf1_sel_res_up = SND_TF1.res_up; tf1_sel_res_dn = SND_TF1.res_dn;
        tf2_sel_sup_up = SND_TF2.sup_up; tf2_sel_sup_dn = SND_TF2.sup_dn; tf2_sel_res_up = SND_TF2.res_up; tf2_sel_res_dn = SND_TF2.res_dn;
        tf3_sel_sup_up = SND_TF3.sup_up; tf3_sel_sup_dn = SND_TF3.sup_dn; tf3_sel_res_up = SND_TF3.res_up; tf3_sel_res_dn = SND_TF3.res_dn;
        
   }
   if(final_snd_mode == 2)
   {
        tf1_sel_sup_up = SND_TF1.sup_up_fresh; tf1_sel_sup_dn = SND_TF1.sup_dn_fresh; tf1_sel_res_up = SND_TF1.res_up_fresh; tf1_sel_res_dn = SND_TF1.res_dn_fresh;
        tf2_sel_sup_up = SND_TF2.sup_up_fresh; tf2_sel_sup_dn = SND_TF2.sup_dn_fresh; tf2_sel_res_up = SND_TF2.res_up_fresh; tf2_sel_res_dn = SND_TF2.res_dn_fresh;
        tf3_sel_sup_up = SND_TF3.sup_up_fresh; tf3_sel_sup_dn = SND_TF3.sup_dn_fresh; tf3_sel_res_up = SND_TF3.res_up_fresh; tf3_sel_res_dn = SND_TF3.res_dn_fresh;
   }
   
  
   if(type == 1)
   {
      //check for buy
      if(tf1_sel_sup_up != 0 && tf1_sel_sup_dn != 0 && 
         MarketInfo(this.strSymbol,MODE_ASK) < tf1_sel_sup_up && 
         MarketInfo(this.strSymbol,MODE_ASK) > tf1_sel_sup_dn
        )
        {
            this.TRADING_SND = SND_TF1;
            return(true);
        }
      if(tf2_sel_sup_up != 0 && tf2_sel_sup_dn != 0 && 
         MarketInfo(this.strSymbol,MODE_ASK) < tf2_sel_sup_up && 
         MarketInfo(this.strSymbol,MODE_ASK) > tf2_sel_sup_dn
        )
        {
            this.TRADING_SND = SND_TF2;
            return(true);
        }
      if(tf3_sel_sup_up != 0 && tf3_sel_sup_dn != 0 && 
         MarketInfo(this.strSymbol,MODE_ASK) < tf3_sel_sup_up && 
         MarketInfo(this.strSymbol,MODE_ASK) > tf3_sel_sup_dn
        )
        {
            this.TRADING_SND = SND_TF3;
            return(true);
        }
   }
   if(type == 2)
   {
      //check for sell
      if(tf1_sel_res_up != 0 && tf1_sel_res_dn != 0 && 
         MarketInfo(this.strSymbol,MODE_BID) < tf1_sel_res_up && 
         MarketInfo(this.strSymbol,MODE_BID) > tf1_sel_res_dn
        )
        {
            this.TRADING_SND = SND_TF1;
            return(true);
        }
      if(tf2_sel_res_up != 0 && tf2_sel_res_dn != 0 && 
         MarketInfo(this.strSymbol,MODE_BID) < tf2_sel_res_up && 
         MarketInfo(this.strSymbol,MODE_BID) > tf2_sel_res_dn
        )
        {
            this.TRADING_SND = SND_TF2;
            return(true);
        }
      if(tf3_sel_res_up != 0 && tf3_sel_res_dn != 0 && 
         MarketInfo(this.strSymbol,MODE_BID) < tf3_sel_res_up && 
         MarketInfo(this.strSymbol,MODE_BID) > tf3_sel_res_dn
        )
        {
            this.TRADING_SND = SND_TF3;
            return(true);
        }
   }
    
   return(false);
}

bool clsBot02::blWithinBOS()
{
   if(STRUC_TF3.intTrend == 0) {this.TRADING_STRUC = STRUC_TF3; return(true); }
   if(STRUC_TF4.intTrend == 0) {this.TRADING_STRUC = STRUC_TF4; return(true); }
   if(STRUC_TF5.intTrend == 0) {this.TRADING_STRUC = STRUC_TF5; return(true); }
   return(false);
}

bool clsBot02::blWithinFIBO(int type)
{
    //if(CheckPointer(this.TRADING_SND) == POINTER_DYNAMIC)
    //{
       //get the BOS index and draw FIBO
       int bos_idx = this.TRADING_STRUC.BOS._BOS_index;
       //use a short method to create FIBO
       clsFibo FIBO(this.strSymbol,this.TRADING_STRUC.intPeriod);
       FIBO.EA_MODE = true;
       FIBO.intFiboLookBack = bos_idx;
       FIBO.Updater(TimeCurrent());
       Print("Prepare Draw Fibo");
       switch(type)
       {
           case 1:
               if (FIBO.CUR_FIBO._active == 1 &&
                   //FIBO.CUR_FIBO._FIBOLowValue >= this.TRADING_SND.sup_dn &&
                   MarketInfo(this.strSymbol,MODE_ASK) <= FIBO.CUR_FIBO._FIBO50Value
                  )
                  {
                       return(true);
                  }
               break;
           case 2:
               if (FIBO.CUR_FIBO._active == 1 &&
                   //FIBO.CUR_FIBO._FIBOHighValue <= this.TRADING_SND.res_up &&
                   MarketInfo(this.strSymbol,MODE_BID) >= FIBO.CUR_FIBO._FIBO50Value
                  )
                  {
                       return(true);
                  }
               break;
       };
       
   //}
   return (false);
}

bool clsBot02::blBuyLogic(SIGNAL_LIST &signal)
{
     if( 
         this.blSNDDirection(1) && 
         this.blWithinBigSND(1) && 
         this.blWithinSND(1)  &&
         this.blWithinBOS() && 
         this.blWithinFIBO(1) &&
         CheckPointer(this.TRADING_SND) == POINTER_DYNAMIC
       )
      {
         //alert identifier : TRADING_SND_res_up + TRADING_SND_res_dn + TRADING_SND_sup_up + TRADING_SND_sup_dn 
         long alert_identifier = (int)this.TRADING_SND.res_up + (int)this.TRADING_SND.res_dn + (int)this.TRADING_SND.sup_up + (int)this.TRADING_SND.sup_dn;
         if (this.longAlertIdentifier !=  alert_identifier)
         {
              Alert("[EUPORIAFIX ALERT] : Buy Opportunity Present at ",this.strSymbol);
              this.longAlertIdentifier =  alert_identifier;
         }     
                   
         double ask = MarketInfo(this.strSymbol,MODE_ASK);
         signal._symbol  = this.strSymbol;
         signal._entry   = ask;
         signal._sl      = this.TRADING_SND.sup_dn - sl_x_pip * pips(this.strSymbol);
         double sl_point = signal._entry - signal._sl;
         double sl_pip   = sl_point / pips(this.strSymbol);
         if(sl_pip == 0) return(false);
         signal._lot     = Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,this.strSymbol,sl_pip) :MM.dblLotSizePerRisk(this.strSymbol,sl_pip);
         signal._tp      = signal._entry + RR_Ratio * sl_point;
         signal._magic = this.intBotMagic;
         Print("Buy Signal Present");
         return(true);
         
      }
     return(false);
}

bool clsBot02::blSellLogic(SIGNAL_LIST &signal)
{
     if( 
         this.blSNDDirection(2) && 
         this.blWithinBigSND(2) && 
         this.blWithinSND(2) 
         && this.blWithinBOS() && 
         this.blWithinFIBO(2) &&
         CheckPointer(this.TRADING_SND) == POINTER_DYNAMIC
       )
      {
         long alert_identifier = (int)this.TRADING_SND.res_up + (int)this.TRADING_SND.res_dn + (int)this.TRADING_SND.sup_up + (int)this.TRADING_SND.sup_dn;
         if (this.longAlertIdentifier !=  alert_identifier)
         {
              Alert("[EUPORIAFIX ALERT] : Sell Opportunity Present at ",this.strSymbol);
              this.longAlertIdentifier =  alert_identifier;
         } 
         
         double bid = MarketInfo(this.strSymbol,MODE_BID);
         signal._symbol  = this.strSymbol;
         signal._entry   = bid;
         signal._sl      = this.TRADING_SND.res_up + sl_x_pip * pips(this.strSymbol);
         double sl_point = signal._sl - signal._entry;
         double sl_pip   = sl_point / pips(this.strSymbol);
         if(sl_pip == 0) return(false);
         signal._lot     = Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,this.strSymbol,sl_pip) :MM.dblLotSizePerRisk(this.strSymbol,sl_pip);
         signal._tp      = signal._entry - RR_Ratio * sl_point;
         signal._magic = this.intBotMagic;
         Print("Sell Signal Present");
         return(true);
         
      }
     return(false);
}





void clsBot02::Breakeven(void)
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

void clsBot02::Trailing(void)
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