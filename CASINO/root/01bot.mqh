//#define BUY_SELL_BALANCE false // => just comment out this line
#include "/MASTER_BOT.mqh"
#include "/MASTER_INDI.mqh"
#include "/VOLA.mqh"
#include "/MMI.mqh"
#include "/TRADE_ENHANCER.mqh"
#include "/SESSION.mqh"
#include "/GSHEET_DIRECTIONS.mqh"
#include "HEDGE.mqh"
#include "STRUCTURE_NEW.mqh"
#include "/LINEAR_REGRESSION.mqh"
#include "/PRICE_ACTION.mqh"
#include "/KAHLER.mqh"

clsVola *VOLA;
clsMMI  *MMI;
clsTradeEnhancer *ENHANCE;
clsSession *SESSION;
clsMasterIndi *INDI;
clsGsheet *GSHEET;
clsHedge *HEDGER;

clsStructure *STRUCTURE;
clsLinearRegression *LR;
clsLinearRegression *BIG_LR;
clsPriceAction *PA;
clsPriceAction *PA_M30;
clsPriceAction *PA_H1;
clsPriceAction *PA_H4;
clsPriceAction *PA_D1;
clsKahler *KAHLER;

int    intLastDifficultDir;

enum   BE_MODE  
{
    PIP_MODE    = 1,
    PECENT_MODE = 2
};

enum   EA_MODE
{
   TREND_MODE,
   COUNTER_TREND_MODE,
   COMBINE
};

//BOT SPECIFIC INPUT
extern string _tmp4_ = "===== STRATEGY INPUT =====";
extern EA_MODE  TRADE_MODE = TREND_MODE;
extern int  entry_magic_number = 98765;
extern int  x_bar_distance = 0;
extern int  sl_x_pip = 20; 
extern double RR_Ratio = 10;
extern double equity_cut_percent = 5;
extern bool   Use_Pyramid = true;
extern double Pyramid_Pos_Pip = 15;
extern double Pyramid_Neg_Pip = 15;
extern period MMI_PERIOD = M15;
extern double Pip_Dev_To_Open = 15;
extern double Recover_Pip_Dev_To_Open = 30;
extern double Profit_Lot_Multiplier = 200;
extern bool   Single_Direction = true;
extern double macd_threshold = 0.0001;
extern double macd_extreme_threshold = 0.7;
extern double mmi_threshold = 50;
extern double atr_threshold = 3;
extern double force_sl_cut = 100;
extern double SurgeMaxLot = 0.6;
extern double SurgePip = 35;
extern double SurgeMultiplier = 2;
extern ENUM_TIMEFRAMES trend_period = PERIOD_H4;
extern string _tmp5_ = "===== BREAKEVEN SETTINGS =====";
extern bool   Use_BreakEven = true;
extern BE_MODE Breakeven_Mode = 1; 
extern double BreakEven_Input = 100;
extern string _tmp6_ = "===== TRAILING SETTINGS =====";
extern bool   Use_Trailing = true;
extern double Trailing_Percent_Input = 3;
extern bool   UseReverse = false;
extern bool   OnlyLong   = false;
extern bool   OnlyShort  = false;
extern int    revive_gap = 90;
extern double park_vol_dn_threshold   = 0.05;
extern double park_vol_up_threshold   = 0.65;
extern int    hedge_trigger_trade = 7;

class clsBot01 : 
     public  clsMasterBot
{
     public:
          clsBot01(string strInputSymbol); //do nothing, same as parent
          ~clsBot01();
          //UNIQUE PART FOR EACH BOT//
          void   Updater();  //Unique Individual Indicator Update Function to Run Indicator
          bool   blBuyLogic   (SIGNAL_LIST &signal); // unique buy  logic for each child bot
          bool   blSellLogic  (SIGNAL_LIST &signal); // unique sell logic for each child bot
          bool   blOpenAllowed (double new_entry_price);
          bool   blRangingMarket();
          bool   blLRHedge();
          //bool   blCloseAllowed(int intInputType, double dblInputCheckPrice, clsTradeClass &TRADE);
          //void   CloseTrade(clsTradeClass &TRADE);
          void   Breakeven();
          void   Trailing();
          void   CloseAll(int type=3);
          void   TimeClose();
          void   JumpClose();
          //IMPORTANT : TO PUT ENTRY, SL, TP in each buy sell logic
          //UNIQUE PART FOR EACH BOT//
          
     protected:
          void   CommentEquity();
          double dblMaxEquity;
          double dblMaxDD;
          void   Strategy_1(int type);
          void   Strategy_2(int type);
          void   Strategy_3(int type);
          void   Strategy_4(int type);
          void   Strategy_5(int type);
          bool   blDuplicateTradeTagExist(int type, int magic, string strTag);
          void   EnterBuy(TRADE_COMMAND &signal, bool reverse=false);
          void   EnterSell(TRADE_COMMAND &signal, bool reverse=false);
          void   MultiplyUnrealizedLossedReturn();
          void   HedgeTradeCloseInProfit();
          double dblMaxLotInLoss(int magic, int type);
          double dblMaxLotInWin (int magic, int type);
          double dblTotalLot(int magic);
          double dblMaxLotPrice(int magic, int type);
          void   MonitorTp(bool long_allowed=true, bool short_allowed=true);
          double dblAverageEntryPrices(int magic, int order_type);
          double dblMinEntryPrices(int magic, int order_type);
          double dblMaxEntryPrices(int magic, int order_type);
          double dblPyramidLots(TRADE_COMMAND &trade, double pos_dev_pip=20, double neg_dev_pip=20);
          double dblMinDeviateLot(TRADE_COMMAND &trade,double dev_pip, bool reverse=false);
          double dblStochK;
          double dblStochD;
          double dblHighPrev;
          double dblLowPrev;
          double dblClosePrev;
          datetime dtDifficultTime;
          int    intTrend();
          int    intTotalBuy();
          int    intTotalSell();
          double dblTotalBuyLot();
          double dblTotalSellLot();
          bool   blSNDDirection(int type);
          bool   blWithinStructure(int type);
          bool   blIsExtreme(int type, int candle, int x_lookback);
          double dblLotCalculate();
          bool   blMAStrongTrend(int type);
          bool   blExtremeZone(int type);
          bool   blStrongATR();
          bool   blCounterPriceNear  (int type, double entry);
          bool   blFollowPriceAllowed(int type, double entry);
          bool   blMarketMeanReverting();
          bool   blSuperJump(int type);
          void   TimeReachedCloseInProfit();
          void   ReduceBoxSize();
          void   Strategy_3_CloseEquivalentTrade();
          void   StopLossCut();
          void   SentimentSurgeClose();
          bool   blDifficultSituationCheck(int type);
          bool   blBodyRange();
          int    intDailyDirection();
          int    intShortTrend();
          int    intShortOsc();
          int    intRSIMom();
          int    intExtremeZone();
          int    intFiveSoldier();
          int    intInsideBarBreak();
          bool   blClimbDown();
          bool   blHedgeCondition(int type);
          void   CheckLastCurTrend(int magic);
          bool   blInterDistanceGapWidened(int type, int magic);
          bool   blInterTimeGapWidened(int type, int magic, bool check_cur_time=false);
          bool   blStrongTrend;
          void   ExtraHedgeCondition(int magic);
          double dblParkinsonVolatility();
          double dblParkinsonPrev;
          datetime dtForceCutTime;
          int    intSupportIdx();
          int    intResistanceIdx();
          int    intBullCandleIdx();
          int    intBearCandleIdx();
          
     private:
          //clsTradeClass *TRADE;
          int    intBotPeriod;
          int    intPrevSignal;
          datetime dtPrevSignalCrossTime;
          bool   blTimingCheck(int type);
          bool   blBaseCheck(int type);
          bool   blConfirmationOneCheck(int type);
          bool   blConfirmationTwoCheck(int type);
          bool   blConfirmationFinalCheck(int type);
          double ask_prev;
          double bid_prev;
          double dblRSI;
          datetime dtStopTradingDate;
          double dblATR[];
          int    intStrat1Magic;
          int    intCurTrend;
          int    intPrevTrend;
          
          
};


clsBot01::clsBot01(string strInputSymbol):clsMasterBot(strInputSymbol)
{
     this.intBotMagic = entry_magic_number; //NEED OVERRIDE MAGIC NUMBER
     Print("Create Bot01 for ",this.strSymbol);
     //Print("One Pip is ",pips(strSymbol));
     intBotPeriod = ChartPeriod();
     VOLA = new clsVola(strSymbol,intBotPeriod);
     MMI  = new clsMMI(strSymbol,MMI_PERIOD);
     ENHANCE = new clsTradeEnhancer(strSymbol,intBotPeriod);
     SESSION = new clsSession();
     INDI    = new clsMasterIndi(strSymbol,intBotPeriod);
     GSHEET = new clsGsheet();
     HEDGER = new clsHedge(TRADE,MM,strSymbol,dblLotCalculate(),intBotPeriod);
     STRUCTURE = new clsStructure(strSymbol,intBotPeriod);
     LR     = new clsLinearRegression(strSymbol,intBotPeriod);
     BIG_LR = new clsLinearRegression(strSymbol,PERIOD_D1);
     PA     = new clsPriceAction(strSymbol,intBotPeriod,true);
     PA_M30 = new clsPriceAction(strSymbol,PERIOD_M30,true);
     PA_H1  = new clsPriceAction(strSymbol,PERIOD_H1,true);
     PA_H4  = new clsPriceAction(strSymbol,PERIOD_H4,true);
     PA_D1  = new clsPriceAction(strSymbol,PERIOD_D1,true);
     KAHLER = new clsKahler(strSymbol,intBotPeriod,true);
     //intCurTrend = 1;
     intLastDifficultDir = 0;
}

clsBot01::~clsBot01()
{
     if(CheckPointer(VOLA) == POINTER_DYNAMIC) delete VOLA;
     if(CheckPointer(MMI)  == POINTER_DYNAMIC) delete MMI;
     if(CheckPointer(ENHANCE) == POINTER_DYNAMIC) delete ENHANCE;
     if(CheckPointer(SESSION) == POINTER_DYNAMIC) delete SESSION;
     if(CheckPointer(INDI) == POINTER_DYNAMIC) delete INDI;
     if(CheckPointer(GSHEET)  == POINTER_DYNAMIC) delete GSHEET;
     if(CheckPointer(HEDGER)  == POINTER_DYNAMIC) delete HEDGER;
     if(CheckPointer(ENHANCE)  == POINTER_DYNAMIC) delete ENHANCE;
     if(CheckPointer(STRUCTURE)  == POINTER_DYNAMIC) delete STRUCTURE;
     if(CheckPointer(LR) == POINTER_DYNAMIC) delete LR;
     if(CheckPointer(BIG_LR) == POINTER_DYNAMIC) delete BIG_LR;
     if(CheckPointer(PA) == POINTER_DYNAMIC) delete PA;
     if(CheckPointer(PA_M30) == POINTER_DYNAMIC) delete PA_M30;
     if(CheckPointer(PA_H1) == POINTER_DYNAMIC) delete PA_H1;
     if(CheckPointer(PA_H4) == POINTER_DYNAMIC) delete PA_H4;
     if(CheckPointer(PA_D1) == POINTER_DYNAMIC) delete PA_D1;
     if(CheckPointer(KAHLER) == POINTER_DYNAMIC) delete KAHLER;
}

void clsBot01::CommentEquity(void)
{
    dblMaxEquity = dblMaxEquity == 0 ? AccountEquity() : AccountEquity() > dblMaxEquity ? AccountEquity() : dblMaxEquity;
    double current_dd = dblMaxEquity - AccountEquity();
    if(current_dd > 0)
    {
        //meaning in DD
        if(current_dd > dblMaxDD) dblMaxDD = current_dd;
    }
    string string_1 = "Equity : "+(string)AccountEquity()+"\n";
    string string_2 = "Max Equity : "+(string)dblMaxEquity+"\n";
    string string_3 = "Max DD : "+(string)dblMaxDD+"\n";
    string string_4 = "Individial Pseudo Max Equity : "+(string)MM.dblMaxPseudoEquity+"\n";
    string string_5 = "Individial Pseudo Equity : "+(string)MM.dblPseudoEquity+"\n";
    string string_6 = "Individial Max Pseudo DD : "+(string)MM.dblMaxPseudoDD+"\n";
    string string_7 = "Last Difficult Situation is "+(string)intLastDifficultDir+"\n";
    //Print("MM Count Max Equity is ",MM.dblMaxPseudoEquity);
    //Print("MM Count Current Equity is ",MM.dblPseudoEquity);
    string string_8  = HEDGER.blHedgeTag  ? "Position Hedged\n" : "\n";
    string string_9  = HEDGER.blHedgeTag ? "Hedge Reverse status : "+(string)HEDGER.blHedgePostReverseTag+"\n" : "\n";
    string string_10 = HEDGER.blHedgeTag ? "Hedge Initiator : "+(string)HEDGER.intHedgeInitiator+"\n" : "\n";
    string string_11 = HEDGER.blHedgeTag ? "Hedge Ranging : "+(string)HEDGER.blHedgeRangingTag+"\n" : "\n";
    string string_12 = "Total Buy Lot is "+(string)dblTotalBuyLot()+" buy price is : "+(string)HEDGER.dblAverageEntryPrices(intStrat1Magic,1)+"\n";
    string string_13 = "Total Sell Lot is "+(string)dblTotalSellLot()+" sell price is : "+(string)HEDGER.dblAverageEntryPrices(intStrat1Magic,2)+"\n";
    string string_14 = "Predicted Average Buy Price "+(string)HEDGER.dblPredictedAvgPrice(intStrat1Magic,1)+"\n";
    string string_15 = "Predicted Average Sell Price "+(string)HEDGER.dblPredictedAvgPrice(intStrat1Magic,2)+"\n";
    string string_16 = "Predicted Post Reverse Buy Price "+(string)HEDGER.dblReversePredictedAvgPrice(intStrat1Magic,2)+"\n";
    string string_17 = "Predicted Post Reverse Sell Price "+(string)HEDGER.dblReversePredictedAvgPrice(intStrat1Magic,1)+"\n";
    string string_18 = "Current OB Level is "+(string)ArraySize(PA.OBLVLs)+"\n";
    string string_19 = "Near support is "+(string)intSupportIdx()+"\n";
    string string_20 = "Near resistance is "+(string)intResistanceIdx()+"\n";
    string string_21 = "FU Bull Candle is "+(string)intBullCandleIdx()+"\n";
    string string_22 = "FU Bear Candle is "+(string)intBearCandleIdx()+"\n";
    //string string_9 = blHedgeTag  ? "Position in Hedge\n" : "\n";
    string final_string = string_1 + string_2 + string_3 + string_4 + string_5 + string_6 + string_7 + string_8 + string_9 + string_10 + string_11 + string_12 + string_13 + string_14 + string_15 + string_16 + string_17 + string_18 + string_19 + string_20 + string_21 + string_22;
    Comment(final_string);
    
    
    //Comment("Max Equity : ",dblMaxEquity);
    //Comment("Max DD : ",dblMaxDD);
}

bool clsBot01::blBuyLogic(SIGNAL_LIST &signal)
{
     return(false);
}

bool clsBot01::blSellLogic(SIGNAL_LIST &signal)
{
    return(false);
}

int clsBot01::intShortOsc()
{
    int trend = 0;
    double osc = iRSI(strSymbol,intBotPeriod,14,PRICE_CLOSE,0);
    if(osc >= 70) trend = 1;
    if(osc <= 30) trend = 2;
    return(trend);
}

void clsBot01::ExtraHedgeCondition(int magic)
{
    if(HEDGER.blHedgeTag) return;
    double buy_min_price  = dblMinEntryPrices(magic,OP_BUY);
    double sell_min_price = dblMinEntryPrices(magic,OP_SELL);
    double buy_max_price  = dblMaxEntryPrices(magic,OP_BUY);
    double sell_max_price = dblMaxEntryPrices(magic,OP_SELL);
    double max_price      = MathMax(buy_max_price,sell_max_price);
    double min_price      = MathMin(buy_min_price,sell_min_price);
    double gap            = (max_price - min_price)/pips(strSymbol);
    double ask            = MarketInfo(strSymbol,MODE_ASK);
    double bid            = MarketInfo(strSymbol,MODE_BID);
    double total_buy      = NormalizeDouble(dblTotalBuyLot(),2);
    double total_sell     = NormalizeDouble(dblTotalSellLot(),2);
    
    //int custom_gap_pip = 5;
    double custom_gap_pip = iATR(strSymbol,intBotPeriod,14,1) * 1 / pips(strSymbol);
    //if(gap < 80 && gap > 50) custom_gap_pip = 20;
    //if(gap < 50) return;
    //if(gap < 80) custom_gap_pip = 20;
    
    
    
    //if(intLastDifficultDir == 1 )
    if(intLastDifficultDir == 1)
    {
         if(total_buy > total_sell && bid < min_price - custom_gap_pip * pips(strSymbol))
         {
             HEDGER.HedgeStart(2,magic,true);
         }
    }
    //if(intLastDifficultDir == 2)
    if(intLastDifficultDir == 2)
    {
         if(total_buy < total_sell && ask > max_price + custom_gap_pip * pips(strSymbol))
         {
             HEDGER.HedgeStart(1,magic,true);
         }
    }
}

void clsBot01::CheckLastCurTrend(int magic)
{
   if(ArraySize(TRADE._terminal_trades) == 0) return;
   double last_lot = 0;
   int    last_type = -1;
   for(int i = ArraySize(TRADE._terminal_trades) - 1; i>= 0; i--)
   {
        //Print("Monitoring Sl Tp");
        if(TRADE._terminal_trades[i]._active == false &&
           TRADE._terminal_trades[i]._order_symbol == strSymbol &&
           TRADE._terminal_trades[i]._magic_number == magic
          )
        {
             if(TRADE._terminal_trades[i]._hedge_trade == false)
             {
               last_lot = TRADE._terminal_trades[i]._order_lot;
               last_type = TRADE._terminal_trades[i]._order_type;
             }
             break;
        }
   }
   if(last_type > -1 && last_lot >= dblLotCalculate() * reverse_multiplier * 125)
   {
        if(last_type == 0) intCurTrend = 2;
        if(last_type == 1) intCurTrend = 1;
   }
}

void clsBot01::StopLossCut(void)
{
    int strat_3_magic = intBotMagic + 333;
    int strat_2_magic = intBotMagic + 222;
    if(TRADE.intTotalBuyCount(strSymbol,strat_3_magic) + TRADE.intTotalSellCount(strSymbol,strat_3_magic) > 1) return;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
        //Print("Monitoring Sl Tp");
        if(TRADE._terminal_trades[i]._active == true &&
           TRADE._terminal_trades[i]._order_symbol == strSymbol &&
           TRADE._terminal_trades[i]._magic_number == strat_3_magic
          )
        {
             if(TRADE._terminal_trades[i]._order_type == 0)
             {
                   if((TRADE._terminal_trades[i]._open_price - TRADE._terminal_trades[i]._close_price) / pips(strSymbol) > force_sl_cut)
                   {
                       Print("Prepare Strategy 2 Buy");
                       //if(TRADE.intTotalTradeCount(strSymbol,strat_2_magic) >= 1) ExpertRemove();
                       Strategy_2(1);
                       
                       //CloseAll();
                   }
             }
             if(TRADE._terminal_trades[i]._order_type == 1)
             {
                   if((TRADE._terminal_trades[i]._close_price - TRADE._terminal_trades[i]._open_price) / pips(strSymbol) > force_sl_cut)
                   {
                       Strategy_2(2);
                       //CloseAll();
                   }
             }
        }
    }
}

void clsBot01::MonitorTp(bool long_allowed=true, bool short_allowed=true)
{
    TRADE_LIST trade_to_reverse_list[];
    //Print("Check Monitor SL TP");
    //if(this.StealthMode == true)
    //{
         //LOOP AGAIN TO CHECK THE ORDER STOP LOSS IF IN STEALTH MODE
         for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
         {
              //Print("Monitoring Sl Tp");
              if(TRADE._terminal_trades[i]._active == true)
              {
                    if(Use_MM)
                    {
                       
                        //if(money_management_mode==YOAV_MODE)this.YoavTrade(this._terminal_trades[i]);
                        
                    }
                    //Check Active Trade Stop Loss TP
                    if(TRADE._terminal_trades[i]._order_type == 0) //buy trade
                    {
                         if(long_allowed == false) return;
                         if( TRADE._terminal_trades[i]._take_profit != 0 &&
                             MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_BID) >= TRADE._terminal_trades[i]._take_profit
                           )
                         {
                               double win_profit  = TRADE.dblTotalWinningProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               double loss_profit = TRADE.dblTotalLossingProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               if(win_profit > InpMultFloatLossReturn * MathAbs(loss_profit)) 
                               {
                                  if(!OrderClose(TRADE._terminal_trades[i]._ticket_number,TRADE._terminal_trades[i]._order_lot,
                                                MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_BID),TRADE.intSlippage))
                                  {
                                      //Alert("Failed to Close BUY Trade of Ticket ID ",TRADE._terminal_trades[i]._ticket_number);
                                  }
                                  /*
                                  if(TRADE._terminal_trades[i]._ticket_number == 15)
                                  {
                                     //Alert("Win Profit is ",win_profit);
                                     //Alert("Loss Profit is ",loss_profit);
                                     ExpertRemove();
                                  }
                                  */
                                  else
                                  {
                                    TRADE._terminal_trades[i]._active = false;
                                    //Alert("Buy Profit Reached Close here");
                                    CloseAll(); //HERE
                                  }
                              } 
                         
                         }
                         
                    }
                    if(TRADE._terminal_trades[i]._order_type == 1) //sell trade
                    {
                         if(short_allowed == false) return;
                         if(  
                              TRADE._terminal_trades[i]._take_profit != 0 &&
                              MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_ASK) <= TRADE._terminal_trades[i]._take_profit
                           )
                         {
                               
                               double win_profit  = TRADE.dblTotalWinningProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               double loss_profit = TRADE.dblTotalLossingProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               if(win_profit > InpMultFloatLossReturn * MathAbs(loss_profit)) 
                               {
                                  if(!OrderClose(TRADE._terminal_trades[i]._ticket_number,TRADE._terminal_trades[i]._order_lot,
                                             MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_ASK),TRADE.intSlippage))
                                    {
                                         //Alert("Failed to Close SELL Trade of Ticket ID ",TRADE._terminal_trades[i]._ticket_number);
                                    }
                                  else
                                  {
                                    TRADE._terminal_trades[i]._active = false;
                                    //Alert("Sell Profit Reached Close here");
                                    CloseAll(); //HERE
                                  }
                                  /*
                                  if(TRADE._terminal_trades[i]._ticket_number == 15)
                                  {
                                     //Alert("Win Profit is ",win_profit);
                                     //Alert("Loss Profit is ",loss_profit);
                                     ExpertRemove();
                                  }
                                  */
                               }
                         }
                         
                    }
              }
         }
    //}
    
    
    
}


void clsBot01::CloseAll(int type = 3)
{
     if(type == 1 || type == 3 )
     {
        TRADE_COMMAND BUY_CLOSE;
        BUY_CLOSE._action = MODE_TCLSE;
        BUY_CLOSE._symbol = this.strSymbol;
        BUY_CLOSE._order_type = 0;
        BUY_CLOSE._magic  = 0;
        TRADE.CloseTradeAction(BUY_CLOSE);
     }
     if(type == 2 || type == 3 )
     {
        TRADE_COMMAND SELL_CLOSE;
        SELL_CLOSE._action = MODE_TCLSE;
        SELL_CLOSE._symbol = this.strSymbol;
        SELL_CLOSE._order_type = 1;
        SELL_CLOSE._magic  = 0;
        TRADE.CloseTradeAction(SELL_CLOSE);
     }
}

int clsBot01::intFiveSoldier()
{
    int power = 0;
    for(int i = 1; i <= 5; i++)
    {
        double close = iClose(strSymbol,PERIOD_D1,i);
        double open  = iOpen(strSymbol,PERIOD_D1,i);
        if(close > open) power++;
        if(close < open) power--;
    }
    if(power == 5)  return(1);
    if(power == -5) return(2);
    return(0);
}

int clsBot01::intInsideBarBreak()
{
    double h2 = iHigh(strSymbol,PERIOD_D1,2);
    double h1 = iHigh(strSymbol,PERIOD_D1,1);
    double h0 = iHigh(strSymbol,PERIOD_D1,0);
    double l2 = iLow(strSymbol,PERIOD_D1,2);
    double l1 = iLow(strSymbol,PERIOD_D1,1);
    double l0 = iLow(strSymbol,PERIOD_D1,0);
    //double bid = MarketInfo(strSymbol,MODE_BID);
    //double ask = MarketInfo(strSymbol,MODE_ASK);
    int direction = 0;
    
    if(h2 > h1 && l2 < l1)
    {
         if(h0 > h2 && l0 > l2) direction = 1;
         if(l0 < l2 && h0 < h2) direction = 2;
    }
    return(direction);
    //double range_2 = iHigh(strSymbol,PERIOD_D1,2) - iLow(strSymbol,PERIOD_D1,2);
    //double range_1 = iHigh(strSymbol,PERIOD_D1,1) - iLow(strSymbol,PERIOD_D1,1);
}

int clsBot01::intTrend(void)
{
    double close  = iClose(strSymbol,PERIOD_D1,1);
    double ma_200 = iMA(strSymbol,PERIOD_D1,200,0,MODE_EMA,PRICE_CLOSE,1);
    int trend = close >= ma_200 ? 1 : 2;
    return(trend);
}

int clsBot01::intShortTrend()
{
    double ma_2   = iMA(strSymbol,intBotPeriod,2,0,MODE_EMA,PRICE_CLOSE,0);
    double ma_10  = iMA(strSymbol,intBotPeriod,10,0,MODE_EMA,PRICE_CLOSE,0);
    double ma_8   = iMA(strSymbol,intBotPeriod,8,0,MODE_EMA,PRICE_CLOSE,0);
    double ma_24  = iMA(strSymbol,intBotPeriod,24,0,MODE_EMA,PRICE_CLOSE,0);
    double ma_100 = iMA(strSymbol,intBotPeriod,100,0,MODE_EMA,PRICE_CLOSE,0);
   
    int trend = 0;
    //if(ma_8 > ma_24 && ma_24 > ma_100) trend = 1;
    //if(ma_8 < ma_24 && ma_24 < ma_100) trend = 2;
    if(ma_24 > ma_100) trend = 1;
    if(ma_24 < ma_100) trend = 2;
    //if(ma_2 > ma_10) trend = 1;
    //if(ma_2 < ma_10) trend = 2;
    return(trend);
}

bool clsBot01::blBodyRange(void)
{
   double body_1 = iHigh(strSymbol,PERIOD_D1,1) - iLow(strSymbol,PERIOD_D1,1);
   double body_2 = iHigh(strSymbol,PERIOD_D1,2) - iLow(strSymbol,PERIOD_D1,2);
   double atr  = iATR(strSymbol,PERIOD_D1,14,1);
   if(body_2 >= 2.5 * body_1 && body_2 >= 2.5 * atr)
   {
      return(false);
   }
   return(true);
}

bool clsBot01::blStrongATR()
{
   double atr   = iATR(strSymbol,MMI_PERIOD,3,0);
   if(atr > atr_threshold * pips(strSymbol))
   {
       return(true);
   }
   return(false);
}

bool clsBot01::blExtremeZone(int type)
{
   double macd  = iMACD(strSymbol,PERIOD_M1,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
   double threshold = macd_extreme_threshold;
   if(type == 1)
   {
       if(macd > threshold)
       {
           return(true);
       }
   }
   if(type == 2)
   {
       if(macd < -threshold)
       {
           return(true);
       }
   }
   return(false);
}

int clsBot01::intRSIMom()
{
   double rsi = iRSI(strSymbol,PERIOD_H1,14,PRICE_CLOSE,0);
   double rsi_prev = iRSI(strSymbol,PERIOD_H1,14,PRICE_CLOSE,1);
   int mom = 0;
   if(rsi > rsi_prev) mom = 1;
   if(rsi < rsi_prev) mom = 2;
   return(mom);
}

bool clsBot01::blMarketMeanReverting(void)
{
   if(MMI.dblMMI != 888 && MMI.dblMMI >= mmi_threshold)
   {
       return(true);
   }
   return(false);
}

bool clsBot01::blMAStrongTrend(int type)
{
    double ma_6  = iMA(strSymbol,MMI_PERIOD,2,0,MODE_EMA,PRICE_CLOSE,0);
    double ma_20 = iMA(strSymbol,MMI_PERIOD,5,0,MODE_EMA,PRICE_CLOSE,0);
    double macd  = iMACD(strSymbol,MMI_PERIOD,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
    double macd_sig = iMACD(strSymbol,MMI_PERIOD,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
    if(type == 1)
    {
        if(macd > macd_sig)
        {
            return(true);
        }
    }
    if(type == 2)
    {
        if(macd < macd_sig)
        {
            return(true);
        }
    }
    /*
    if(type == 1)
    {
        if(ma_6 - ma_20 >= 1 * pips(strSymbol) && ma_6 - ma_20 <= 10 * pips(strSymbol))
        {
            return(true);
        }
    }
    if(type == 2)
    {
        if(ma_20 - ma_6 >= 1 * pips(strSymbol) && ma_20 - ma_6 <= 10 * pips(strSymbol))
        {
             return(true);
        }
    }
    
    double threshold = macd_threshold;
    if(type == 1)
    {
        if(macd > threshold)
        {
           return(true);
        }
    }
    if(type == 2)
    {
        if(macd < -threshold)
        {
           return(true);
        }
    }
    */
    return(false);
}



bool clsBot01::blIsExtreme(int type, int candle, int x_lookback)
{
     //double cur_low  = iLow(strSymbol,intBotPeriod,candle);
     //double cur_high = iHigh(strSymbol,intBotPeriod,candle);
     if(type == 1)
     {
           double cur_low  = iLow(strSymbol,intBotPeriod,candle);
           int lowest_idx  = iLowest(strSymbol,intBotPeriod,MODE_LOW,x_lookback,candle);
           double lowest   = iLow(strSymbol,intBotPeriod,lowest_idx);
           if(cur_low <= lowest) return(true);
     }
     
     if(type == 2)
     {
           double cur_high  = iHigh(strSymbol,intBotPeriod,candle);
           int highst_idx   = iHighest(strSymbol,intBotPeriod,MODE_HIGH,x_lookback,candle);
           double highest   = iHigh(strSymbol,intBotPeriod,highst_idx);
           if(cur_high >= highest) return(true);
     }
     return(false);
}

bool clsBot01::blInterTimeGapWidened(int type, int magic, bool check_cur_time=false)
{
     datetime buy_time[];
     datetime sell_time[];
     datetime max_buy_time  = 0;
     datetime max_sell_time = 0;
     
     int consec_buy_gap[];
     int consec_sell_gap[];
     
     for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
     {
          if(TRADE._terminal_trades[i]._active == true &&
             TRADE._terminal_trades[i]._order_symbol == strSymbol &&
             TRADE._terminal_trades[i]._magic_number == magic
            )
         {
              if(TRADE._terminal_trades[i]._order_type == 0)
              {
                   int buy_size = ArraySize(buy_time);
                   ArrayResize(buy_time,buy_size+1);
                   buy_time[buy_size] = TRADE._terminal_trades[i]._order_opened_time;
              }
              if(TRADE._terminal_trades[i]._order_type == 1)
              {
                   int sell_size = ArraySize(sell_time);
                   ArrayResize(sell_time,sell_size+1);
                   sell_time[sell_size] = TRADE._terminal_trades[i]._order_opened_time;
              }
         }
     }
     max_buy_time = ArraySize(buy_time) > 1 ? buy_time[ArrayMaximum(buy_time)] : max_buy_time;
     max_sell_time = ArraySize(sell_time) > 1 ? sell_time[ArrayMaximum(sell_time)] : max_sell_time;
     
     if(type == 1)
     {
         ArrayResize(consec_buy_gap,ArraySize(buy_time)-1);
         for(int i = 0; i < ArraySize(buy_time)-1; i++)
         {
              consec_buy_gap[i] = (int)MathAbs(buy_time[i] - buy_time[i+1]);
         }
         //we loop the sequence
         int gap_size = ArraySize(consec_buy_gap);
         int cross_factor = (gap_size - 1)/2;
         int cross_count  = 0;
         int wide_factor  = 10;
         if(gap_size > 1)
         {
              int idx_max    = ArrayMaximum(consec_buy_gap);
              double max_gap = idx_max >= 0 ? consec_buy_gap[idx_max] : 0;
              
              int idx_min    = ArrayMinimum(consec_buy_gap);
              double min_gap = idx_min >= 0 ? consec_buy_gap[idx_min] : 0;
              
              wide_factor = 3;
              
              if(max_gap == 0) return(false);
              //if(max_gap == 0 || max_gap < 20 * 60) return(false);
              max_gap = check_cur_time ? (double)TimeCurrent() - max_buy_time : max_gap;
              for(int i = 0; i < gap_size; i++)
              {
                   double cur_gap = consec_buy_gap[i];
                   if(max_gap > cur_gap * wide_factor)
                   {
                        cross_count++;
                   }
                   
                   
              }
              /*
              Print("Time Max gap is ",max_gap);
              Print("Time Cross Count is ",cross_count);
              Print("Time Cross Factor is ",cross_factor);
              */
              if(cross_count >= cross_factor)
              {
                   //meaning the widest gap is bigger than wide factor * size
                   //Print("Time True");
                   return(true);
              }
         }
     }
     
     if(type == 2)
     {
         ArrayResize(consec_sell_gap,ArraySize(sell_time)-1);
         for(int i = 0; i < ArraySize(sell_time)-1; i++)
         {
              consec_sell_gap[i] = (int)MathAbs(sell_time[i] - sell_time[i+1]);
              Print("Gap ",i," is ",consec_sell_gap[i]);
         }
         //we loop the sequence
         int gap_size = ArraySize(consec_sell_gap);
         int cross_factor = (gap_size - 1)/2;
         int cross_count  = 0;
         
         int wide_factor  = 10;
         //Print("Time A");
         if(gap_size > 1)
         {
              
              int idx_max    = ArrayMaximum(consec_sell_gap);
              double max_gap = idx_max >= 0 ? consec_sell_gap[idx_max] : 0;
              int idx_min    = ArrayMinimum(consec_sell_gap);
              double min_gap = idx_min >= 0 ? consec_sell_gap[idx_min] : 0;
              /*
              Print("Max Gap Idx is ",idx_max);
              Print("Max Gap is ",max_gap);
              Print("Min Gap Idx is ",idx_min);
              Print("Min Gap is ",min_gap);
              */
              if(max_gap == 0) return(false);
              max_gap = check_cur_time ? (double)TimeCurrent() - max_sell_time : max_gap;
              //if(max_gap == 0 || max_gap < 20 * 60) return(false);
              for(int i = 0; i < gap_size; i++)
              {
                   double cur_gap = consec_sell_gap[i];
                   if(max_gap > cur_gap * wide_factor)
                   {
                        cross_count++;
                   }
              }
              /*
              Print("Sell Time Max gap is ",max_gap);
              Print("Sell Time Cross Count is ",cross_count);
              Print("Sell Time Cross Factor is ",cross_factor);
              */
              if(cross_count >= cross_factor)
              {
                   //meaning the widest gap is bigger than wide factor * size
                   return(true);
              }
         }
     }
     return(false);
}


bool clsBot01::blInterDistanceGapWidened(int type, int magic)
{
     double buy_price[];
     double sell_price[];
     
     double consec_buy_gap[];
     double consec_sell_gap[];
     
     for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
     {
          if(TRADE._terminal_trades[i]._active == true &&
             TRADE._terminal_trades[i]._order_symbol == strSymbol &&
             TRADE._terminal_trades[i]._magic_number == magic
            )
         {
              if(TRADE._terminal_trades[i]._order_type == 0)
              {
                   int buy_size = ArraySize(buy_price);
                   ArrayResize(buy_price,buy_size+1);
                   buy_price[buy_size] = TRADE._terminal_trades[i]._open_price;
              }
              if(TRADE._terminal_trades[i]._order_type == 1)
              {
                   int sell_size = ArraySize(sell_price);
                   ArrayResize(sell_price,sell_size+1);
                   sell_price[sell_size] = TRADE._terminal_trades[i]._open_price;
              }
         }
     }
     
     if(type == 1)
     {
         ArrayResize(consec_buy_gap,ArraySize(buy_price)-1);
         for(int i = 0; i < ArraySize(buy_price)-1; i++)
         {
              consec_buy_gap[i] = MathAbs(buy_price[i] - buy_price[i+1]);
         }
         //we loop the sequence
         int gap_size = ArraySize(consec_buy_gap);
         int cross_factor = (gap_size - 1)/1 - 1;
         int cross_count  = 0;
         int wide_factor  = 8;
         if(gap_size > 1)
         {
              int idx_max    = ArrayMaximum(consec_buy_gap);
              double max_gap = idx_max > 0 ? consec_buy_gap[idx_max] : 0;
              if(max_gap == 0) return(false);
              for(int i = 0; i < gap_size; i++)
              {
                   double cur_gap = consec_buy_gap[i];
                   if(max_gap > cur_gap * wide_factor)
                   {
                        cross_count++;
                   }
              }
              
              Print("Cross count is ",cross_count);
              Print("Max Gap is ",max_gap);
              Print("Cross factor is ",cross_factor);
              Print("Cross Condition is ",cross_count >= cross_factor);
              
              if(cross_count >= cross_factor)
              {
                   //meaning the widest gap is bigger than wide factor * size
                   //Print("Hello");
                   return(true);
              }
         }
     }
     
     if(type == 2)
     {
         ArrayResize(consec_sell_gap,ArraySize(sell_price)-1);
         for(int i = 0; i < ArraySize(sell_price)-1; i++)
         {
              consec_sell_gap[i] = MathAbs(sell_price[i] - sell_price[i+1]);
         }
         //we loop the sequence
         int gap_size = ArraySize(consec_sell_gap);
         int cross_factor = (gap_size - 1)/1 - 1;
         int cross_count  = 0;
         int wide_factor  = 8;
         if(gap_size > 1)
         {
              int idx_max    = ArrayMaximum(consec_sell_gap);
              double max_gap = idx_max > 0 ? consec_sell_gap[idx_max] : 0;
              if(max_gap == 0) return(false);
              for(int i = 0; i < gap_size; i++)
              {
                   double cur_gap = consec_sell_gap[i];
                   if(max_gap > cur_gap * wide_factor)
                   {
                        cross_count++;
                   }
              }
              if(cross_count >= cross_factor)
              {
                   //meaning the widest gap is bigger than wide factor * size
                   return(true);
              }
         }
     }
     return(false);
}

double clsBot01::dblMaxLotPrice(int magic, int type)
{
    type = type - 1;
    double max_lot = DBL_MIN;
    double max_lot_entry = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true       &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol  &&
              TRADE._terminal_trades[i]._order_type   == type &&
              TRADE._terminal_trades[i]._magic_number == magic
             )
           {
                max_lot = MathMax(max_lot,TRADE._terminal_trades[i]._order_lot);
                max_lot_entry = max_lot == TRADE._terminal_trades[i]._order_lot ? TRADE._terminal_trades[i]._entry : max_lot_entry;
           }
    }
    return(max_lot_entry);
}

void clsBot01::SentimentSurgeClose()
{
    if(!blStrongTrend) return;
    if(ArraySize(dblATR) < 2) return;
    double atr_1 = NormalizeDouble(dblATR[0],4);//iATR(strSymbol,PERIOD_M1,2,1);
    double atr_2 = NormalizeDouble(dblATR[1],4);//iATR(strSymbol,PERIOD_M1,2,2);
    //Print("atr_1 is ",atr_1);
    //Print("atr_2 is ",atr_2);
    double close_1 = iClose(strSymbol,PERIOD_M1,1);
    double close_2 = iClose(strSymbol,PERIOD_M1,2);
    int    direction = close_1 > close_2 ? 1 : close_1 < close_2 ? 2 : 0;
    double sum_buy_lot  = dblTotalBuyLot();
    double sum_sell_lot = dblTotalSellLot();
    
    if(atr_2 == 0) return;
    
    //if(atr_1 > SurgePip * pips(strSymbol))
    if( atr_1 / atr_2 >= SurgeMultiplier && atr_1 >= SurgePip * pips(strSymbol) && atr_1 <= 2 * SurgePip * pips(strSymbol) )
    {
        Print("Sentiment Surge 3 Checking");
        Print("atr_1 is ",atr_1);
        Print("atr_2 is ",atr_2);
        
        double total_lot = sum_buy_lot + sum_sell_lot;
        if(total_lot > dblLotCalculate() * 60) 
        //if(total_lot > SurgeMaxLot) 
        {
           //Alert("Sum lot more than", SurgeMaxLot);
           //ExpertRemove();
           return;
        }
        //Print("Sentiment surged");
        //ExpertRemove();
        if(direction == 1)
        {
            //Print("Sell Sentiment Surge
            if(sum_sell_lot != 0 && sum_sell_lot > sum_buy_lot)
            {
                //Alert("Sell Sentiment Surge, Close All");
                dtDifficultTime = TimeCurrent();
                CloseAll();
            }
        }
        if(direction == 2)
        {
            if(sum_buy_lot != 0 && sum_buy_lot > sum_sell_lot)
            {
                //Alert("Buy Sentiment Surge, Close All");
                dtDifficultTime = TimeCurrent();
                CloseAll();
            }
        }
        
    }
}

void clsBot01::JumpClose()
{
   double total_buy_lot  = dblTotalBuyLot();
   double total_sell_lot = dblTotalSellLot();
   
   double high  = iHigh(strSymbol,intBotPeriod,1);
   double low   = iLow(strSymbol, intBotPeriod,1);
   double open  = iOpen(strSymbol,intBotPeriod,1);
   double close = iClose(strSymbol,intBotPeriod,1);
   double bid   = MarketInfo(strSymbol,MODE_BID);
   /*
   if(bid >= 1827.34)
   //if(TimeCurrent() >= D'2021.05.07 15:31')
   {
       Print("High is ",high);
       Print("Low is ",low);
       Print("Open is ",open);
       Print("Close is ",close);
       Print("Current Time is ",TimeCurrent());
       Print("Bid is ",bid);
       Print("Diff is ",bid - open);
       Print("Condition Check is ",(bid - open >= 90 * pips(strSymbol) && bid > open &&  total_sell_lot > total_buy_lot)); 
       Print("Condition 1 Check is ",(bid - open >= 90 * pips(strSymbol)));
       Print("Condition 2 Check is ",bid > open);
       Print("Condition 3 Check is ",total_sell_lot > total_buy_lot);
       ExpertRemove();
   }
   */
   if(
        (bid - open >= 90 * pips(strSymbol) && bid > open &&  total_sell_lot > total_buy_lot) ||
        (open - bid >= 90 * pips(strSymbol) && bid < open   && total_sell_lot < total_buy_lot)
     ) 
   {
        CloseAll();
        dtForceCutTime = TimeCurrent();
        if(bid > open) intLastDifficultDir = 2;
        if(bid < open) intLastDifficultDir = 1;
   }
}

void clsBot01::MultiplyUnrealizedLossedReturn()
{
    double sum_win  = TRADE.dblTotalWinningProfit(this.strSymbol,this.intBotMagic);
    double sum_loss = TRADE.dblTotalLossingProfit(this.strSymbol,this.intBotMagic);
    
    if(
         (sum_win > 0 && sum_loss != 0 && MathAbs(sum_loss)/sum_win <= 0.05)
      ) 
    {
       CloseAll();
    }
}

bool clsBot01::blSuperJump(int type)
{
    int factor = 50;
    double close = iClose(strSymbol,intBotPeriod,1);
    double open  = iOpen(strSymbol,intBotPeriod,1);
    
    if(type == 1)
    {
        if(close - open >= factor * pips(strSymbol))
        {
            return(true);
        }
    }
    if(type == 2)
    {
        if(open - close >= factor * pips(strSymbol))
        {
            return(true);
        }
    }
    return(false);
}


void clsBot01::Updater()
{
    if(TimeCurrent() <  D'2021.06.15 20:44')
    //if(TimeCurrent() <  D'2020.06.12 01:15')
    {
        //return;
        //ExpertRemove();
    }
    if(TimeCurrent() >= D'2021.06.17 15:21')
    {
      //ExpertRemove();
    }
    
    
    
    if(PA.blNewBar()) PA.Updater(TimeCurrent());
    if(PA_M30.blNewBar()) PA_M30.Updater(TimeCurrent());
    if(PA_H1.blNewBar())  PA_H1.Updater(TimeCurrent());
    if(PA_H4.blNewBar())  PA_H4.Updater(TimeCurrent());
    if(PA_D1.blNewBar())  PA_D1.Updater(TimeCurrent());
    if(TRADE.dblTotalOngoingProfit(strSymbol,intStrat1Magic) <= - 1100)
    {
        Print(this.strSymbol+" Forced Cut Loss, Preparing to Close Trade ");
        CloseAll();
    }
    
    if(MM.blPseudoMarginStoppedOut(this.strSymbol))
    {
         Alert(this.strSymbol+" Being Stopped Out, Preparing to Close Trade ");
         this.CloseAll();
         ExpertRemove();
    }
    CommentEquity();
    
    intCurTrend = intDailyDirection();
    TimeReachedCloseInProfit();
    if(intPrevTrend != intCurTrend)intLastDifficultDir = 0;
      
    
    HEDGER.Updater();
    if(HEDGER.blHedgeTag)
    {
         return;
    }
    CommentEquity();
    
    //Breakeven();
    //Trailing();
    
    if(!IsTesting()){GSHEET.Updater(this.strSymbol);}
    if(GSHEET.intDirection == 444) return;
    
    int direction = intDailyDirection();
    if(
        !blDifficultSituationCheck(1) && !blDifficultSituationCheck(2) && TimeCurrent() - dtDifficultTime >= 5 * 60 && TimeCurrent() - dtForceCutTime >= 24 * 60 * 60
        &&  TimeCurrent() - HEDGER.dtDifficultTime >= 24 * 60 * 60
      )
    { 
       
          double ask = MarketInfo(strSymbol,MODE_ASK);
          double bid = MarketInfo(strSymbol,MODE_BID);
         
          if(intLastDifficultDir != 1 && intCurTrend == 1 )  Strategy_1(1);
          if(intLastDifficultDir != 2 && intCurTrend == 2 )  Strategy_1(2);
    }
    
    intPrevTrend = intCurTrend;
}

void clsBot01::TimeReachedCloseInProfit()
{
    datetime avg_time_opened = TRADE.dtAverageOpenTime(strSymbol,intBotMagic);
    //Print("Avg Time Open is ",avg_time_opened); 
    if(avg_time_opened != 0 && TimeCurrent() - avg_time_opened >= 6 * intBotPeriod * 60)
    {
       double total_lots_open = TRADE.dblTotalLotOpened(strSymbol,intBotMagic);
       double presume_profit = total_lots_open * Profit_Lot_Multiplier;
       
       //modify small lots
       if(avg_time_opened != 0 && TimeCurrent() - avg_time_opened >= 40 * intBotPeriod * 60)
       {
            //Print("Time Small lots exceed");
            if(total_lots_open <= dblLotCalculate() * 3) 
            {
               presume_profit = 0;
               Print("Small lots drag");
               //ExpertRemove();
               //CloseAll();
            }
       }
       
       
       if(TRADE.dblTotalOngoingProfit(strSymbol,intBotMagic) >= presume_profit)
       //if(TRADE.dblTotalOngoingProfit(strSymbol,intBotMagic) >= 0)
       {
         if(total_lots_open != dblLotCalculate())
         {
            //Alert("Extra Lot Total Profit is ",TRADE.dblTotalOngoingProfit(strSymbol,intBotMagic));
            //ExpertRemove();
         }
         //Alert("Time Reached Close Profit");
         CloseAll();
       }
    }
}


void clsBot01::TimeClose()
{
    if(TRADE.intTotalBuyCount(strSymbol,intBotMagic) + TRADE.intTotalSellCount(strSymbol,intBotMagic)>=1)
    {
         datetime avg_time_opened = TRADE.dtAverageOpenTime(strSymbol,intBotMagic); 
         Print("Avg Time Opened is ",avg_time_opened);
         Print("Time Diff is ",TimeCurrent() - avg_time_opened);
         if(avg_time_opened != 0 && TimeCurrent() - avg_time_opened >= 6 * intBotPeriod * 60)
         {
             //Alert("Time Close here");
             CloseAll();
         }
    }
} 

void clsBot01::Strategy_3_CloseEquivalentTrade()
{
    
    double buy_lot  = dblTotalBuyLot();
    double sell_lot = dblTotalSellLot();
    //double total_lot = 
    
    datetime avg_time_opened = TRADE.dtAverageOpenTime(strSymbol,intStrat1Magic); 
    
    //if(intTotalBuy()== 1 && intTotalSell() == 1 && buy_lot == sell_lot)
    if(buy_lot != 0 && sell_lot != 0)
    {
        if(MathAbs(buy_lot - sell_lot) <= 0.03)
        {  
           //if(TRADE.dblTotalOngoingProfit(strSymbol,intStrat1Magic) <= -100) return;
           int day = 1;
           if(avg_time_opened != 0 && TimeDayOfWeek(avg_time_opened) >= 5) day = 3;
           if(avg_time_opened != 0 && TimeCurrent() - avg_time_opened >= day * 24 * 60 * 60)
           {
                //Print("Avg Time is ",avg_time_opened);
                //Print("Time of day is ",TimeDayOfWeek(avg_time_opened));
                Print("Stucked Trade Close here");
                CloseAll();
           }
        }
        if(buy_lot == sell_lot)
        {
           if(avg_time_opened != 0 && TimeCurrent() - avg_time_opened >= 1* 60)
           {
                Print("Hedged Trade Close here");
                CloseAll();
                //ExpertRemove();
           }
        }
    }
}

void clsBot01::ReduceBoxSize(void)
{
    int range_loss_to_close = 50;
    double min_buy_price   = DBL_MAX;
    double min_sell_price  = DBL_MAX;
    double max_sell_price  = DBL_MIN;
    double max_buy_price   = DBL_MIN;
    double min_buy_profit  = 0;
    double min_sell_profit = 0;
    double max_sell_profit = 0;
    double max_buy_profit  = 0;
    int    min_buy_ticket  = 0;
    int    min_sell_ticket = 0;
    int    max_sell_ticket = 0;
    int    max_buy_ticket  = 0;
    
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol //&&
              //TRADE._terminal_trades[i]._magic_number == magic     
              )
           {
                if(TRADE._terminal_trades[i]._order_type == 0)
                {
                    min_buy_price  = MathMin(min_buy_price,TRADE._terminal_trades[i]._entry);
                    min_buy_profit = min_buy_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._order_profit : min_buy_profit;
                    min_buy_ticket = min_buy_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._ticket_number : min_buy_ticket;
                    max_buy_price  = MathMax(max_buy_price,TRADE._terminal_trades[i]._entry);
                    max_buy_profit = max_buy_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._order_profit : max_buy_profit;
                    max_buy_ticket = max_buy_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._ticket_number : max_buy_ticket;
                    
                    //buy_count ++;
                }
                if(TRADE._terminal_trades[i]._order_type == 1)
                {
                    min_sell_price  = MathMin(min_sell_price,TRADE._terminal_trades[i]._entry);
                    min_sell_profit = min_sell_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._order_profit : min_sell_profit;
                    min_sell_ticket = min_sell_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._ticket_number : min_sell_ticket;
                    max_sell_price = MathMax(max_sell_price,TRADE._terminal_trades[i]._entry);
                    max_sell_profit = max_sell_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._order_profit : max_sell_profit;
                    max_sell_ticket = max_sell_price == TRADE._terminal_trades[i]._entry ? TRADE._terminal_trades[i]._ticket_number : max_sell_ticket;
                    //sell_count++;
                }
                
           }
    }
    
    //CLOSE TOP BOX
    if(max_buy_ticket != 0)
    {
        if(OrderSelect(max_buy_ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
             double range  = OrderClosePrice() - OrderOpenPrice();
             double profit = OrderProfit();
             double lot    = OrderLots();
             double range_pip = range/pips(strSymbol);
             if(range_pip < - range_loss_to_close)
             {
                  for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
                  {
                       if(
                          TRADE._terminal_trades[i]._active       == true      &&
                          TRADE._terminal_trades[i]._order_symbol == strSymbol &&
                          TRADE._terminal_trades[i]._ticket_number != max_buy_ticket
                          //TRADE._terminal_trades[i]._magic_number == magic     
                          )
                       {
                            if(TRADE._terminal_trades[i]._order_profit >= profit &&
                               TRADE._terminal_trades[i]._order_profit <= 1.2 * profit
                               )
                            {
                                 double bid = MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_BID);
                                 double ask = MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_ASK);
                                 double close_price = MathMod(TRADE._terminal_trades[i]._order_type,2) == 0 ? bid : ask;
                                 if(!OrderClose(TRADE._terminal_trades[i]._ticket_number,TRADE._terminal_trades[i]._order_lot,
                                                close_price,slippage) &&
                                    !OrderClose(max_buy_ticket,lot,
                                                bid,slippage)
                                   )
                                  {
                                      //Alert("Failed To Close Upper Max Buy BOx");
                                  }          
                            }
                            
                       }
                  }
             }
        }
    }
    
    //CLOSE BOTTOM BOX
    if(min_sell_ticket != 0)
    {
        if(OrderSelect(min_sell_ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
             double range  = OrderOpenPrice() - OrderClosePrice();
             double profit = OrderProfit();
             double lot    = OrderLots();
             double range_pip = range/pips(strSymbol);
             if(range_pip < - range_loss_to_close)
             {
                  for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
                  {
                       if(
                          TRADE._terminal_trades[i]._active       == true      &&
                          TRADE._terminal_trades[i]._order_symbol == strSymbol &&
                          TRADE._terminal_trades[i]._ticket_number != min_sell_ticket
                          //TRADE._terminal_trades[i]._magic_number == magic     
                          )
                       {
                            if(TRADE._terminal_trades[i]._order_profit >= profit &&
                               TRADE._terminal_trades[i]._order_profit <= 1.2 * profit
                               )
                            {
                                 double bid = MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_BID);
                                 double ask = MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_ASK);
                                 double close_price = MathMod(TRADE._terminal_trades[i]._order_type,2) == 0 ? bid : ask;
                                 if(!OrderClose(TRADE._terminal_trades[i]._ticket_number,TRADE._terminal_trades[i]._order_lot,
                                                close_price,slippage) &&
                                    !OrderClose(min_sell_ticket,lot,
                                                ask,slippage)
                                   )
                                  {
                                      //Alert("Failed To Close Lower Min Sell BOx");
                                  }          
                            }
                            
                       }
                  }
             }
        }
    }
}

bool clsBot01::blFollowPriceAllowed(int type, double entry)
{
    double min_buy_price   = DBL_MAX;
    double min_sell_price  = DBL_MAX;
    double max_sell_price  = DBL_MIN;
    double max_buy_price   = DBL_MIN;
    int buy_count = 0;
    int sell_count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
        if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol //&&
              //TRADE._terminal_trades[i]._magic_number == magic     
              )
           {
                if(TRADE._terminal_trades[i]._order_type == 0)
                {
                    min_buy_price = MathMin(min_buy_price,TRADE._terminal_trades[i]._entry);
                    max_buy_price = MathMax(max_buy_price,TRADE._terminal_trades[i]._entry);
                    buy_count ++;
                }
                if(TRADE._terminal_trades[i]._order_type == 1)
                {
                    max_sell_price = MathMax(max_sell_price,TRADE._terminal_trades[i]._entry);
                    min_sell_price = MathMin(min_sell_price,TRADE._terminal_trades[i]._entry);
                    sell_count++;
                }
                
           }
    }
    int total_count = buy_count + sell_count;
    if(min_sell_price == DBL_MAX || max_buy_price == DBL_MIN)
    {
         return(true);
    }
    double max_price = MathMax(max_buy_price,MathMax(min_sell_price,entry));
    double min_price = MathMin(max_buy_price,MathMin(min_sell_price,entry));
    int ten_multiplier = (int)((max_price - min_price)/pips(strSymbol) / 10);
    int max_trade_allowed = ten_multiplier * 1;
    
    if(total_count < 10) return(true);
    if(total_count <= max_trade_allowed)    return(true);
    /*
    if(total_count >= 10)
    {
       if(type == 1 && 
          ( entry > max_buy_price ||
            MathAbs(entry - max_buy_price)/pips(strSymbol) < 2
          )
         )  
         {return(true);}
      
       if( type == 2 && 
           (entry < min_sell_price ||
            MathAbs(entry - min_sell_price)/pips(strSymbol) < 2
           )
         ) 
       {
          return(true);
       }
    }
    else
    {
      if(total_count < 10) return(true);
      if(total_count <= max_trade_allowed)    return(true);
    }
    */
    return(false);
}

bool clsBot01::blCounterPriceNear(int type, double entry)
{
    double min_buy_price   = DBL_MAX;
    double min_sell_price  = DBL_MAX;
    double max_sell_price  = DBL_MIN;
    double max_buy_price   = DBL_MIN;
    int buy_count = 0;
    int sell_count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol //&&
              //TRADE._terminal_trades[i]._magic_number == magic     
              )
           {
                if(TRADE._terminal_trades[i]._order_type == 0)
                {
                    min_buy_price = MathMin(min_buy_price,TRADE._terminal_trades[i]._entry);
                    max_buy_price = MathMax(max_buy_price,TRADE._terminal_trades[i]._entry);
                    buy_count ++;
                }
                if(TRADE._terminal_trades[i]._order_type == 1)
                {
                    max_sell_price = MathMax(max_sell_price,TRADE._terminal_trades[i]._entry);
                    min_sell_price = MathMin(min_sell_price,TRADE._terminal_trades[i]._entry);
                    sell_count++;
                }
                
           }
    }
    if(type == 1)
    {
       if(buy_count == 0 || sell_count == 0) return(true);
       if(min_sell_price != DBL_MAX && max_buy_price != DBL_MIN)
       {
           double range = (max_buy_price - min_sell_price)/pips(strSymbol);
           Print("Range is ",range);
           if((max_buy_price - min_sell_price)/pips(strSymbol) > 40)
           {
             if(entry > min_sell_price)
             {
               return(true);
             }
             else
             {
                 return(false);
                 //Print("Buy Entry Lower than Min Sell Price");
                 //ExpertRemove();
             }
           }
           else
           {
              return(true);
           }
       }
       else
       {
           return(false);
       }
       /*
       if(MathAbs(entry - max_sell_price)/pips(strSymbol) < Pip_Dev_To_Open * 10)
       {
           return(true);
       }
       */
    }
    if(type == 2)
    {
       if(sell_count == 0 || sell_count == 0) return(true);
       if(max_buy_price != DBL_MIN && min_sell_price != DBL_MAX)
       { 
         if((max_buy_price - min_sell_price)/pips(strSymbol) > 40)
         {   
            if (entry < max_buy_price)
            {
               return(true);
            }
            else
            {
                 return(false);
                 //Print("Sell Entry Higher than Max Buy Price");
                 //ExpertRemove();
           }
         }
         else
         {
            return(true);
         }
       }
       else
       {
             return(true);
       }
       /*
       if(MathAbs(entry - min_buy_price)/pips(strSymbol) < Pip_Dev_To_Open * 10)
       {
           return(true);
       }
       */
    }
    return(false);
}

int clsBot01::intTotalBuy()
{
    int count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol
             )
           { 
               if(TRADE._terminal_trades[i]._order_type == 0)
               {
                    count++;
               }
           }
    }
    return(count);
}

int clsBot01::intTotalSell()
{
    int count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol
             )
           { 
               if(TRADE._terminal_trades[i]._order_type == 1)
               {
                    count++;
               }
           }
    }
    return(count);
}

double clsBot01::dblTotalBuyLot()
{
    double count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol
             )
           { 
               if(TRADE._terminal_trades[i]._order_type == 0)
               {
                    count += TRADE._terminal_trades[i]._order_lot;
               }
           }
    }
    return(count);
}

double clsBot01::dblTotalSellLot()
{
    double count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol
             )
           { 
               if(TRADE._terminal_trades[i]._order_type == 1)
               {
                    count += TRADE._terminal_trades[i]._order_lot;
               }
           }
    }
    return(count);
}

double clsBot01::dblTotalLot(int magic)
{
    double lot = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol //&&
              //TRADE._terminal_trades[i]._magic_number == magic     
              )
           {
               lot += TRADE._terminal_trades[i]._order_lot;
           }
     }
     return(lot);
}

double clsBot01::dblMaxLotInLoss(int magic, int type)
{
    type = type - 1;
    double max_lot = DBL_MIN;
    double all_max_lot = DBL_MIN;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              TRADE._terminal_trades[i]._order_type   == type
              //TRADE._terminal_trades[i]._magic_number == magic     
              )
           {
                if(TRADE._terminal_trades[i]._hedge_trade) 
                {
                   //Print("Hedge trade present with ticket ID of ",TRADE._terminal_trades[i]._ticket_number);
                   //ExpertRemove();
                   //continue;
                }
                all_max_lot = MathMax(max_lot,TRADE._terminal_trades[i]._saved_lot);
                if(TRADE._terminal_trades[i]._order_profit < 0)
                {
                    max_lot = MathMax(max_lot,TRADE._terminal_trades[i]._saved_lot);
                }
                
                
           }
    }
    if(max_lot < all_max_lot) max_lot = DBL_MIN;
    
    return(max_lot);
}

double clsBot01::dblMaxLotInWin(int magic, int type)
{
    type = type - 1;
    double max_lot = DBL_MIN;
    double all_max_lot = DBL_MIN;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              TRADE._terminal_trades[i]._order_type   == type
              //TRADE._terminal_trades[i]._magic_number == magic     
              )
           {
                all_max_lot = MathMax(max_lot,TRADE._terminal_trades[i]._saved_lot);
                if(TRADE._terminal_trades[i]._order_profit > 0)
                {
                    max_lot = MathMax(max_lot,TRADE._terminal_trades[i]._saved_lot);
                }
           }
    }
    if(max_lot < all_max_lot) max_lot = DBL_MIN;
    //if(max_lot > 0.2) max_lot = 0.2;
    return(max_lot);
}

double clsBot01::dblParkinsonVolatility()
{
    double sum_hr_squared = 0;
    for(int i = 1; i <= 24; i++)
    {
         double high = MathLog10(iHigh(strSymbol,PERIOD_H1,i));
         double low  = MathLog10(iLow(strSymbol,PERIOD_H1,i));
         double hr_squared = MathPow((high-low),2);
         sum_hr_squared += hr_squared;
    }
    double value = MathSqrt((sum_hr_squared / (4 * MathLog10(2))));
    return(value/pips(strSymbol));
}

int clsBot01::intExtremeZone()
{
    int zone = 0;
    double low  = iLow(strSymbol,PERIOD_D1,1);
    double high = iHigh(strSymbol,PERIOD_D1,1);
    double bid  = MarketInfo(strSymbol,MODE_BID);
    
    if(bid < low) zone = 2;
    if(bid > high)zone = 1;
    return(zone);
}

double clsBot01::dblAverageEntryPrices(int magic, int order_type)
{
    //OUTPUT : 0 / Entry Price
    double sum_entry = 0;
    int    total_entry = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              TRADE._terminal_trades[i]._order_type   == order_type &&
              TRADE._terminal_trades[i]._magic_number == magic
             )
           {
                 sum_entry += TRADE._terminal_trades[i]._entry;
                 total_entry++;
           }
    }
    if(total_entry==0) return(0);
    return(sum_entry/total_entry);
}

double clsBot01::dblMaxEntryPrices(int magic, int order_type)
{
    //OUTPUT : 0 / Entry Price
    double max_entry = DBL_MIN;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              TRADE._terminal_trades[i]._order_type   == order_type
             )
           {
                 max_entry = MathMax(max_entry,TRADE._terminal_trades[i]._entry);
                 
           }
    }
    if(max_entry==DBL_MIN) return(0);
    return(max_entry);
}

double clsBot01::dblMinEntryPrices(int magic, int order_type)
{
    //OUTPUT : 0 / Entry Price
    double min_entry = DBL_MAX;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              TRADE._terminal_trades[i]._order_type   == order_type
             )
           {
                 min_entry = MathMin(min_entry,TRADE._terminal_trades[i]._entry);
                 
           }
    }
    if(min_entry==DBL_MAX) return(0);
    return(min_entry);
}

double clsBot01::dblMinDeviateLot(TRADE_COMMAND &trade,double dev_pip, bool reverse=false)
{
    int    type = trade._order_type;
    double lot  = trade._lots;
    //double avg_price = dblAverageEntryPrices(trade._magic,type);
    double avg_price = 0; 
    if(!reverse)
    {
        avg_price = trade._order_type == 0 || trade._order_type == 2 || trade._order_type == 4 ? dblMinEntryPrices(trade._magic,type) : dblMaxEntryPrices(trade._magic,type);
    }
    else
    {
        avg_price = trade._order_type == 0 || trade._order_type == 2 || trade._order_type == 4 ? dblAverageEntryPrices(trade._magic,type) : dblAverageEntryPrices(trade._magic,type);
        //avg_price = trade._order_type == 0 || trade._order_type == 2 || trade._order_type == 4 ? dblMaxEntryPrices(trade._magic,type) : dblMinEntryPrices(trade._magic,type);
    }
    Print("Average Price is ",avg_price);
    if(avg_price == 0) return(lot); //return to init lot for first trade
    //double diff = MathAbs(trade._entry - avg_price)/pips(trade._symbol);
    
    double diff = 0;
    if(!reverse)
    {
        diff = trade._order_type == 0 || trade._order_type == 2 || trade._order_type == 4 ? (avg_price - trade._entry)/pips(trade._symbol) : (trade._entry - avg_price)/pips(trade._symbol); 
    }
    else
    {
        diff = trade._order_type == 0 || trade._order_type == 2 || trade._order_type == 4 ? (trade._entry - avg_price)/pips(trade._symbol) : (avg_price - trade._entry)/pips(trade._symbol);
    }
    
    double buy_number  = TRADE.intTotalBuyCount(strSymbol,trade._magic);
    double sell_number = TRADE.intTotalSellCount(strSymbol,trade._magic);
    //dev_pip = type == 0 || type == 2 || type == 4 ? dev_pip * 1 : dev_pip * 1;
    //if(!reverse) dev_pip = MathAbs(dev_pip);
    
    //dev_pip = type == 0 || type == 2 || type == 4 ? dev_pip * buy_number : dev_pip * sell_number;
    //dev_pip = type == 0 || type == 2 || type == 4 ? MathPow(dev_pip, buy_number) : MathPow(dev_pip, sell_number);
    
    /*
    int trade_number = (int)(trade._order_type == 0 ? buy_number : sell_number);
    int factor = 4;
    
    if(trade_number > factor)
    {
        dev_pip = dev_pip * (trade_number - factor);
    }
    */
    double yes_range = (iHigh(strSymbol,PERIOD_D1,1) - iLow(strSymbol,PERIOD_D1,1)) / pips(strSymbol);
    
    double factor = 14 * 2;
    dev_pip = yes_range/factor;
    double constant = 1000;
    dev_pip = MathMax(1/yes_range * constant, Pip_Dev_To_Open);
    
    if(diff < dev_pip * 1 )
    {
        return(0);
    }
    
    return(lot);
}




double clsBot01::dblPyramidLots(TRADE_COMMAND &trade, double pos_dev_pip=20, double neg_dev_pip=20)
{
    //OUTPUT : DBL_MIN / Lots Value
    int    type = trade._order_type;
    double lot = trade._lots;
    double avg_price = dblAverageEntryPrices(trade._magic,type);
    if(avg_price == 0) return(lot); //return to init lot for first trade
    double diff = MathAbs(trade._entry - avg_price)/pips(trade._symbol);
    if(type == 0)
    {
         if(trade._entry < avg_price && diff > neg_dev_pip) return(0);
         if(trade._entry > avg_price && diff > pos_dev_pip) return(0);
    }
    if(type == 1)
    {
         //Print("Sell Entry is ",trade._entry);
         //Print("Sell Average Entry is ",avg_price);
         //Print("Sell Diff is ",diff);
         if(trade._entry < avg_price && diff > pos_dev_pip) return(0);
         if(trade._entry > avg_price && diff > neg_dev_pip) return(0);
    }
    return(lot);
}

bool clsBot01::blDuplicateTradeTagExist(int type, int magic, string strTag)
{
    type = type - 1;
    
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              TRADE._terminal_trades[i]._magic_number == magic     &&
              TRADE._terminal_trades[i]._order_type   == type      &&
              TRADE._terminal_trades[i]._trade_entry_tag == strTag
             )
           {
               if(type == 0) 
               {
                   ////Alert("Trade in tag is ",TRADE._terminal_trades[i]._trade_entry_tag);
                   ////Alert("Checked Tag is ",strTag);
                   //ExpertRemove();
               }
               return(true);
           }
    }
    return(false);
}




void clsBot01::HedgeTradeCloseInProfit()
{
    double buy_profit = 0;
    double sell_profit = 0;
    double total_profit = 0;
    int buy_trade = 0;
    int sell_trade = 0;
    double buy_lot = 0;
    double sell_lot = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol 
             )
             {
                 if(TRADE._terminal_trades[i]._order_type   == 0)
                 {
                      buy_profit += TRADE._terminal_trades[i]._order_profit + TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                      buy_lot    += TRADE._terminal_trades[i]._order_lot;
                      buy_trade++;
                 }
                 if(TRADE._terminal_trades[i]._order_type   == 1)
                 {
                      sell_profit += TRADE._terminal_trades[i]._order_profit + TRADE._terminal_trades[i]._order_swap + TRADE._terminal_trades[i]._order_comission;
                      sell_lot    += TRADE._terminal_trades[i]._order_lot;
                      sell_trade++;
                 }
             }
    }
    if(buy_trade + sell_trade >= 3)
    {
        if(equity_cut_percent != 0 && MM.blPseudoEquityCut(equity_cut_percent))
         {
               //Alert(this.strSymbol+" Equity Cut, Preparing to Close Trade ");
               //this.CloseAll();
               //ExpertRemove();
         }
    }
    double total_lot = buy_lot + sell_lot;
    
    if(buy_lot != 0 || sell_lot != 0) 
    {
         if
         (  (buy_lot == sell_lot) ||
             buy_lot  >= sell_lot  ||
             sell_lot >= buy_lot
         )
         {
           total_profit = buy_profit + sell_profit;
           //double presume_profit = (buy_lot + sell_lot) * Profit_Lot_Multiplier;
           //if(total_profit > presume_profit) CloseAll(); 
           //if(total_profit > 0) CloseAll();
           double multiplier = Profit_Lot_Multiplier;
           
           if( (total_lot >= 1000 * dblLotCalculate()) || (buy_trade + sell_trade >= 7) ) multiplier = 10;
           if(total_profit > total_lot * multiplier)
           //if(total_profit > total_lot * Profit_Lot_Multiplier)
           {
            //Alert("Hedge Close Profit, CLose here");
            CloseAll();
           }
           //if(total_profit > presume_profit) CloseAll(); 
         }
         
    }
    
}


void clsBot01::Strategy_1(int type)
{
    int magic = intBotMagic + 111;
    intStrat1Magic = magic;
    string strTag = (string)TimeCurrent();
    //if(!blBodyRange()) return;
    double ask = MarketInfo(strSymbol,MODE_ASK);
    double bid = MarketInfo(strSymbol,MODE_BID);
    double high = iHigh(strSymbol,PERIOD_D1,1);
    double low  = iLow(strSymbol,PERIOD_D1,1);
    double range = iHigh(strSymbol,PERIOD_D1,1) - iLow(strSymbol,PERIOD_D1,1);
    double mid_price = iHigh(strSymbol,PERIOD_D1,1) - (range/2);
    if(type == 1)
    {
        //if(ask < low) return;
        //if(intInsideBarBreak() == 2) return;
        strTag = (string)TimeCurrent()+"BUY";
        //if(intFiveSoldier() == 1 && bid > mid_price) return; //too strong bull, anticipate reversal
        //if(dblMaxLotInLoss(magic,1) >= dblLotCalculate() * 200 && intRSIMom() == 2) return;
        if(!UseReverse)
        {
           if(blDuplicateTradeTagExist(1,magic,strTag) || OnlyShort == true) {}//Alert("Duplicated trade tag is ",strTag); return;}
           if(intTotalBuy() >= 5) 
           {
             HEDGER.HedgeStart(2);
             return;
           }
           Print("Latest Buy Tag is ",strTag);
           TRADE_COMMAND buy_command;
           buy_command._magic = magic;
           buy_command._trade_entry_tag = strTag;
           int bull_idx = intBullCandleIdx();
           double sl = 0;
           if(bull_idx == 1) sl = iLow(strSymbol,intBotPeriod,iLowest(strSymbol,intBotPeriod,MODE_LOW,2,0));
           if(bull_idx == 2) sl = iLow(strSymbol,PERIOD_M30,iLowest(strSymbol,PERIOD_M30,MODE_LOW,2,0));
           if(bull_idx == 3) sl = iLow(strSymbol,PERIOD_H1,iLowest(strSymbol,PERIOD_H1,MODE_LOW,2,0));
           if(bull_idx == 4) sl = iLow(strSymbol,PERIOD_H4,iLowest(strSymbol,PERIOD_H4,MODE_LOW,2,0));
           if(bull_idx == 5) sl = iLow(strSymbol,PERIOD_D1,iLowest(strSymbol,PERIOD_D1,MODE_LOW,2,0));
           EnterBuy(buy_command);
           /*
           buy_command._sl = sl;
           if(sl != 0)
           {
              double sl_pip = (ask - buy_command._sl);
              buy_command._tp = ask + (3 * sl_pip);  
              EnterBuy(buy_command);
           }
           */
        }
        else
        {
           //strTag = (string)FRACTREND_1.dblSellTrendTag + (string)FRACTREND_1.intSellTrendFiboTag + (string)FRACTREND_2.dblSellTrendTag;// + (string)FRACTREND_2.intSellTrendFiboTag;
           if(blDuplicateTradeTagExist(2,magic,strTag) || OnlyLong == true) return;
           Print("Latest Sell Tag is ",strTag);
           TRADE_COMMAND sell_command;
           sell_command._magic = magic;
           sell_command._trade_entry_tag = strTag;
           sell_command._sl = 0;
           EnterSell(sell_command);
        }
              //return(true);
        
    }
    
    if(type == 2)
    {
            //if(bid > high) return;
            //if(intInsideBarBreak() == 1) return;
            strTag = (string)TimeCurrent()+"SELL";
            
            //if(intFiveSoldier() == 2 && bid < mid_price) return; //too strong bear, anticipate reversal
             //if(dblMaxLotInLoss(magic,2) >= dblLotCalculate() * 200 && intRSIMom() == 1) return;
            if(!UseReverse)
            {
              Print("Sell here");
            
              if(blDuplicateTradeTagExist(2,magic,strTag) || OnlyLong == true) return;
              
              if(intTotalSell() >= 5) 
              {
                HEDGER.HedgeStart(1);
                return;
              }
              Print("Latest Sell Tag is ",strTag);
              
              TRADE_COMMAND sell_command;
              sell_command._magic = magic;
              sell_command._trade_entry_tag = strTag;
              sell_command._sl = 0;
              int bear_idx = intBearCandleIdx();
              double sl = 0;
              if(bear_idx == 1) sl = iHigh(strSymbol,intBotPeriod,iHighest(strSymbol,intBotPeriod,MODE_HIGH,2,0));
              if(bear_idx == 2) sl = iHigh(strSymbol,PERIOD_M30,iHighest(strSymbol,PERIOD_M30,MODE_HIGH,2,0));
              if(bear_idx == 3) sl = iHigh(strSymbol,PERIOD_H1,iHighest(strSymbol,PERIOD_H1,MODE_HIGH,2,0));
              if(bear_idx == 4) sl = iHigh(strSymbol,PERIOD_H4,iHighest(strSymbol,PERIOD_H4,MODE_HIGH,2,0));
              if(bear_idx == 5) sl = iHigh(strSymbol,PERIOD_D1,iHighest(strSymbol,PERIOD_D1,MODE_HIGH,2,0));
              EnterSell(sell_command);
              /*
              sell_command._sl = sl;
              if(sl != 0)
              {
                 double sl_pip = (sell_command._sl - bid) ;
                 sell_command._tp = bid - (3 * sl_pip);  
                 EnterSell(sell_command);
              }
              */
            }
            else
            { 
                 if(blDuplicateTradeTagExist(1,magic,strTag) || OnlyShort == true) return;
                 Print("Latest Buy Tag is ",strTag);
                 TRADE_COMMAND buy_command;
                 buy_command._magic = magic;
                 buy_command._trade_entry_tag = strTag;
                 buy_command._sl = 0;
                 EnterBuy(buy_command);
            }
              //return(true);
        
    }
    //return(false);
}

double clsBot01::dblLotCalculate(void)
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

bool clsBot01::blLRHedge()
{
    int lookback = 7;
    int count = 0;
    if(ArraySize(LR.dblClose_ms) > lookback)
    {
       for(int i = 0; i < lookback; i++)
       {
           if(MathAbs(LR.dblClose_ms[i]) > MathAbs(LR.dblClose_ms[i+1]))
           {
               count++;
           }
       }
       if(count >= lookback) return(true);
    }
    return(false);
}

void clsBot01::EnterBuy(TRADE_COMMAND &signal, bool reverse=false)
{
    //reverse : false = martingale, true = anti-martingale
    //if(TRADE.intTotalBuyCount(signal._symbol,signal._magic) >= 1) return; //HERE
    if(Single_Direction && TRADE.intTotalSellCount(signal._symbol,signal._magic) > 0) return;
    signal._action  = MODE_TOPEN;
    double ask = MarketInfo(strSymbol,MODE_ASK);
    signal._symbol  = strSymbol;
    signal._entry   = ask;
    Print("Pre buy sl is ",signal._sl);
    signal._sl      = signal._sl == 0 ? ask - sl_x_pip * pips(strSymbol) : signal._sl;
    Print("Buy strategy stop loss is ",signal._sl);
    signal._order_type = 0;
    double sl_point = signal._entry - signal._sl;
    double sl_pip   = sl_point / pips(this.strSymbol);
    double multiplier = reverse_multiplier;
    int buy_count  = intTotalBuy();
    int sell_count = intTotalSell();
    if(dblLotCalculate() != 0.01)// || reverse_multiplier >= 2)
    {
      if (buy_count <= 2 || buy_count == 4) multiplier = 1;
    }
    if(MathMod(buy_count,3) == 0) multiplier = 1;
    double deficit_lot    = dblTotalSellLot() - dblTotalBuyLot();
    //signal._lots    = deficit_lot <= 0 ? dblLotCalculate() : deficit_lot * multiplier;
    signal._lots      = dblMaxLotInLoss(signal._magic,1) == DBL_MIN ? dblLotCalculate() : dblMaxLotInLoss(signal._magic, 1) * multiplier;
    //signal._lots      = dblMaxLotInWin(signal._magic,2) == DBL_MIN ? dblLotCalculate() : dblMaxLotInWin(signal._magic,2) * multiplier;
    double ongoing_loss = TRADE.dblTotalOngoingProfit(strSymbol,signal._magic);
    double new_lot    = MathAbs(ongoing_loss / 10 / MM.dblPipValuePerLot(strSymbol));
    //signal._lots      = ongoing_loss >= 0 ? dblLotCalculate() : new_lot;
    
    
    
    if(signal._lots == dblLotCalculate() && intTotalSell()>0)
    {
         //signal._lots = dblMaxLotInLoss(signal._magic,2);
    }
    double buy_min_price  = dblMinEntryPrices(signal._magic,OP_BUY);
    double sell_min_price = dblMinEntryPrices(signal._magic,OP_SELL);
    double buy_max_price  = dblMaxEntryPrices(signal._magic,OP_BUY);
    double sell_max_price = dblMaxEntryPrices(signal._magic,OP_SELL);
    double max_price      = MathMax(buy_max_price,sell_max_price);
    double min_price      = MathMin(buy_min_price,sell_min_price);
    double gap            = (max_price - min_price)/pips(strSymbol);
    double mid            = max_price - (max_price - min_price)/2;
    double upper_third    = max_price - (max_price - min_price)*1/3;
    double lower_third    = max_price - (max_price - min_price)*2/3; 
    double sell_avg_price = dblAverageEntryPrices(signal._magic,2);
    double sell_max_lot_price = dblMaxLotPrice(signal._magic,2);
    
    if(max_price != 0 && min_price != 0 && signal._lots != dblLotCalculate() && ask < min_price) signal._lots = 0;
    
    if(signal._lots == dblLotCalculate() && intTotalSell()>  0)
    {
       if(
            (ask > sell_max_price || intShortTrend() == 1) ||
            //ask > sell_max_lot_price &&
            (gap > revive_gap  && ask < upper_third)
         )// intTotalSell() < 10)
       {
           //if(intShortOsc() == 1)
           //signal._lots = deficit_lot > 0 ? deficit_lot : 0;
           int factor = MathMax((int)gap/10,1);
           signal._lots = dblMaxLotInLoss(signal._magic,2)/(factor*reverse_multiplier);
           //if(HEDGER.blHedgeTag == false) HEDGER.HedgeStart(1,signal._magic,true);
       }
    }
    //if(max_lot > 0.2) max_lot = 0.2;
    if(Pip_Dev_To_Open != 0) signal._lots = dblMinDeviateLot(signal,Pip_Dev_To_Open,reverse);
    
    if(signal._lots == 0) return;
    // HERE
    //if (signal._lots > 0.5) return;
    signal._saved_lot = signal._lots;
    signal._tp      = signal._tp == 0 ? signal._entry + RR_Ratio * sl_point : signal._tp;
    //signal._sl      = 0;
    bool need_hedge = false;
    /*
    if(TimeCurrent() >= D'2021.05.11 15:48')
        {
            Print("Time Check");
            Print("Condition 1 A is ",(blInterDistanceGapWidened(1,signal._magic)));
            Print("Condition 2 is ", (dblTotalSellLot() < dblTotalBuyLot() || blInterTimeGapWidened(1,signal._magic,true) || buy_count >= 8));
            ExpertRemove();
        }
        */
    if(
         buy_count > 3 && 
         (blInterDistanceGapWidened(1,signal._magic) || buy_count >= 6 ) &&//|| sell_count >= 1) && 
         (dblTotalSellLot() < dblTotalBuyLot() || blInterTimeGapWidened(1,signal._magic,true) || buy_count >= 9)
      )
    {
        /*
        if(buy_count >= 5)
        {
            Print("Check");
            Print("Condition 1 is ",iATR(strSymbol,PERIOD_M1,2,1) < 8 * pips(strSymbol));
            Print("ATR is : ",iATR(strSymbol,PERIOD_M1,2,1));
            ExpertRemove();
        }
        */
        double atr_1 = iATR(strSymbol,PERIOD_M1,2,1);
        double atr_2 = iATR(strSymbol,PERIOD_M1,2,2);
        if(
             atr_1 < 15 * pips(strSymbol) && blInterTimeGapWidened(1,signal._magic,true) &&
             (max_price - ask)/pips(strSymbol) < 80
          ) 
        {
           //need_hedge = true;
           //ExpertRemove();
        }
        //if(atr_1 / atr_2 >= 1.3) need_hedge = true;
        
    }
    if( need_hedge ) 
    {
       intLastDifficultDir = 1;
       HEDGER.HedgeStart(2,signal._magic);
       return;
    }
    else{TRADE.EnterTrade(signal,true);}
}

void clsBot01::EnterSell(TRADE_COMMAND &signal, bool reverse=false)
{
    /*
    if(TimeCurrent() >= D'2021.04.15 05:47')
    {
        Print("Current Hedge Status is ",HEDGER.blHedgeTag);
        ExpertRemove();
    }
    */
    //reverse : false = martingale, true = anti-martingale
    //if(TRADE.intTotalSellCount(signal._symbol,signal._magic) >= 1) return; //HERE
    if(Single_Direction && TRADE.intTotalBuyCount(signal._symbol,signal._magic) > 0) return;
    signal._action  = MODE_TOPEN;
    double bid = MarketInfo(strSymbol,MODE_BID);
    signal._symbol  = strSymbol;
    signal._entry   = bid;
    Print("Initial signal sl is ",signal._sl);
    signal._sl      = signal._sl == 0 ? bid + sl_x_pip * pips(strSymbol) : signal._sl;
    Print("Sell 1 pip is ",pips(strSymbol));
    Print("Sell bid + sl is ",bid + sl_x_pip * pips(strSymbol));
    Print("Sell strategy stop loss is ",signal._sl);
    signal._order_type = 1;
    double sl_point = signal._sl - signal._entry;
    double sl_pip   = sl_point / pips(this.strSymbol);
    
    double multiplier = reverse_multiplier;
    int sell_count  = intTotalSell();
    int buy_count   = intTotalBuy();
    if(dblLotCalculate() != 0.01)// || reverse_multiplier >= 2)
    {
      if (sell_count <= 2 || sell_count == 4) multiplier = 1;
    }
    if(MathMod(sell_count,3) == 0) multiplier = 1;
    double deficit_lot    = dblTotalBuyLot() - dblTotalSellLot();
    signal._lots    = dblMaxLotInLoss(signal._magic,2) == DBL_MIN ? dblLotCalculate() : dblMaxLotInLoss(signal._magic, 2) * multiplier;
    //signal._lots    = deficit_lot <= 0 ? dblLotCalculate() : deficit_lot * multiplier;
    //signal._lots    = dblMaxLotInWin(signal._magic,1) == DBL_MIN ? dblLotCalculate() : dblMaxLotInWin(signal._magic, 1) * multiplier;
    double ongoing_loss = TRADE.dblTotalOngoingProfit(strSymbol,signal._magic);
    double new_lot    = MathAbs(ongoing_loss / 10 / MM.dblPipValuePerLot(strSymbol));
    //signal._lots      = ongoing_loss >= 0 ? dblLotCalculate() : new_lot;
    
    Print("Check point A lot is ",signal._lots);
    
    double buy_min_price  = dblMinEntryPrices(signal._magic,OP_BUY);
    double sell_min_price = dblMinEntryPrices(signal._magic,OP_SELL);
    double buy_max_price  = dblMaxEntryPrices(signal._magic,OP_BUY);
    double sell_max_price = dblMaxEntryPrices(signal._magic,OP_SELL);
    double max_price      = MathMax(buy_max_price,sell_max_price);
    double min_price      = MathMin(buy_min_price,sell_min_price);
    double gap            = (max_price - min_price)/pips(strSymbol);
    double mid            = max_price - (max_price - min_price)/2;
    double upper_third    = max_price - (max_price - min_price)*1/3;
    double lower_third    = max_price - (max_price - min_price)*2/3; 
    double avg_buy_price  = dblAverageEntryPrices(signal._magic,1);
    double buy_max_lot_price = dblMaxLotPrice(signal._magic,1);
    
    if(max_price != 0 && min_price != 0 && signal._lots != dblLotCalculate() &&  bid > max_price) signal._lots = 0;
    
    
    if(signal._lots == dblLotCalculate() && intTotalBuy()>0) 
    { 
       if(
            (bid < buy_min_price || intShortTrend() == 2 || bid > mid) ||   //intTotalBuy() < 10)
            //bid < buy_max_lot_price &&
            (gap > revive_gap  && bid > lower_third)
         )
       {
           
            //if(intShortOsc() == 2) 
            //signal._lots = deficit_lot > 0 ? deficit_lot : 0;
            Print("Deficit lot is ",deficit_lot);
            Print("Check point B lot is ",signal._lots);
            int factor = MathMax((int)gap/10,1);
            signal._lots = dblMaxLotInLoss(signal._magic,1)/(factor * reverse_multiplier);
            //if(HEDGER.blHedgeTag == false) HEDGER.HedgeStart(2,signal._magic,true);
       }
    }
    if(Pip_Dev_To_Open != 0) signal._lots = dblMinDeviateLot(signal,Pip_Dev_To_Open,reverse);
    Print("Check point C lot is ",signal._lots);
    if(signal._lots == 0) 
    {
      return;
    }
    
    // HERE
    //if (signal._lots > 0.5) return;
    signal._saved_lot = signal._lots;
    signal._tp      = signal._tp == 0 ? signal._entry - RR_Ratio * sl_point : signal._tp;
    //signal._sl      = 0;
    bool need_hedge = false;
    
    /*
    if(TimeCurrent() >= D'2021.09.08 18:47')
        {
            Print("Time Check");
            Print("Condition 1 A is ",(blInterDistanceGapWidened(2,signal._magic)));
            Print("Condition 1 B is ",sell_count >= 6);
            Print("Condition 1 is ",(blInterDistanceGapWidened(2,signal._magic) || sell_count >= 6));
            Print("Condition 2 is ", (dblTotalBuyLot() < dblTotalSellLot() || (blInterTimeGapWidened(2,signal._magic,true)) || sell_count >= 8));
            double atr_1 = iATR(strSymbol,PERIOD_M1,2,1);
            double atr_2 = iATR(strSymbol,PERIOD_M1,2,2);
            Print("ATR 1 is ",atr_1);
            Print("ATR 2 is ",atr_2);
            Print("ATR Check is ",atr_1/atr_2);
            Print("ATR condition is ",atr_1 < 15 * pips(strSymbol));
            Print("Time deviation is ",blInterTimeGapWidened(2,signal._magic,true));
            ExpertRemove();
        }
      */
    if(
          (sell_count > 3) && 
          (blInterDistanceGapWidened(2,signal._magic) || sell_count >= 6) &&//|| buy_count >= 1) &&
          (dblTotalBuyLot() < dblTotalSellLot() || (blInterTimeGapWidened(2,signal._magic,true)) || sell_count >= 9)
      ) 
    {
       double atr_1 = iATR(strSymbol,PERIOD_M1,2,1);
       double atr_2 = iATR(strSymbol,PERIOD_M1,2,2);
       if(
           atr_1 < 15 * pips(strSymbol) && blInterTimeGapWidened(2,signal._magic,true) &&
           (bid - min_price)/pips(strSymbol) < 80
         )
       {
          //need_hedge = true;
          //ExpertRemove();
       }
       //if(atr_1 / atr_2 >= 1.3) need_hedge = true;
    }
    if(need_hedge)
    { 
       intLastDifficultDir = 2;
       HEDGER.HedgeStart(1,signal._magic);
       return;
    }
    else {
      //if(NormalizeDouble(signal._lots,2) == 0.99) ExpertRemove();
      TRADE.EnterTrade(signal,true);
    }
}



void clsBot01::Breakeven(void)
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

void clsBot01::Trailing(void)
{
    if(ArraySize(TRADE._terminal_trades))
    {
       TRADE_COMMAND check_trade;
       check_trade._action = MODE_TCHNG;
       check_trade._trailing_mode  = 1;
       check_trade._trailing_input = 150;
       check_trade._symbol = this.strSymbol;
       TRADE.TrailTrade(check_trade);
    }
}

bool clsBot01::blHedgeCondition(int type)
{
    //return(false);
    int total_buy  = TRADE.intTotalBuyCount(strSymbol,intStrat1Magic);
    int total_sell = TRADE.intTotalSellCount(strSymbol,intStrat1Magic);
    
    double ma24h  = iMA(strSymbol,PERIOD_D1,24,0,MODE_EMA,PRICE_CLOSE,0);
    double ma100h = iMA(strSymbol,PERIOD_D1,100,0,MODE_EMA,PRICE_CLOSE,0);
    
    double ma24h_prev  = iMA(strSymbol,PERIOD_D1,24,0,MODE_EMA,PRICE_CLOSE,1);
    double ma100h_prev = iMA(strSymbol,PERIOD_D1,100,0,MODE_EMA,PRICE_CLOSE,1);
    
    double low   = iLow(strSymbol,PERIOD_D1,0);
    double high  = iHigh(strSymbol,PERIOD_D1,0);
    double close = iClose(strSymbol,PERIOD_D1,0);
    
    double low1  = iLow(strSymbol,PERIOD_D1,1);
    double high1 = iHigh(strSymbol,PERIOD_D1,1);
    
    double ma_up = MathMax(ma24h,ma100h);
    double ma_dn = MathMin(ma24h,ma100h);
    
    double ma_up_prev = MathMax(ma24h_prev,ma100h_prev);
    double ma_dn_prev = MathMin(ma24h_prev,ma100h_prev);
    
    double stop_buy_zone  = ma_up + 0 * pips(strSymbol);
    double stop_sell_zone = ma_dn - 0 * pips(strSymbol);
    
    if(HEDGER.intLastHedgeIntitiator == 1)
    {
        if(high < ma_dn && low < ma_dn) HEDGER.intLastHedgeIntitiator = 0;
    }
    if(HEDGER.intLastHedgeIntitiator == 2)
    {
        if(low > ma_up && high > ma_up) HEDGER.intLastHedgeIntitiator = 0;
    }
    
    if(type == 1 && HEDGER.intLastHedgeIntitiator != 1)
    {
        if(total_sell > 1 && total_sell < 12 && (high >= stop_sell_zone && dblHighPrev < stop_sell_zone && dblHighPrev != 0 && high1 < ma_dn_prev))
        //if(total_sell > 1 && blClimbDown())
        {
           return(true);
        }
    }
    
    if(type == 2 && HEDGER.intLastHedgeIntitiator != 2 )
    {
        if(total_buy > 1 && total_buy < 12 && (low <= stop_buy_zone && dblLowPrev > stop_buy_zone && dblLowPrev != 0 && low1 > ma_up_prev ))
        //if(total_buy > 1 && blClimbDown())
        {
           return(true);
        }
    }
    
    
    dblHighPrev = high;
    dblLowPrev  = low;
    return(false);
}

bool clsBot01::blClimbDown()
{
    double ma24h  = iMA(strSymbol,PERIOD_D1,24,0,MODE_EMA,PRICE_CLOSE,0);
    double ma100h = iMA(strSymbol,PERIOD_D1,100,0,MODE_EMA,PRICE_CLOSE,0);
    
    double ma24h_prev  = iMA(strSymbol,PERIOD_D1,24,0,MODE_EMA,PRICE_CLOSE,1);
    double ma100h_prev = iMA(strSymbol,PERIOD_D1,100,0,MODE_EMA,PRICE_CLOSE,1);
    
    double ma24h_prev2  = iMA(strSymbol,PERIOD_D1,24,0,MODE_EMA,PRICE_CLOSE,2);
    double ma100h_prev2 = iMA(strSymbol,PERIOD_D1,100,0,MODE_EMA,PRICE_CLOSE,2);
    
    double mag_diff      = MathAbs(ma24h - ma100h);
    double mag_diff_prev = MathAbs(ma24h_prev - ma100h_prev);
    double mag_diff_prev2 = MathAbs(ma24h_prev2 - ma100h_prev2);
    
    bool climb_down = mag_diff_prev > mag_diff_prev2 && mag_diff < mag_diff_prev ? true : false;
    Print("mag_diff is ", mag_diff);
    Print("mag_diff_prev is ", mag_diff_prev);
    Print("mag_diff_prev2 is ", mag_diff_prev2);
    Print("Climb down is ",climb_down);
    return(climb_down);
}

bool clsBot01::blRangingMarket()
{
   double atr_14 = iATR(strSymbol,intBotPeriod,14,1);
   double atr_21 = iATR(strSymbol,intBotPeriod,21,1);
   
   if(atr_14 < atr_21) return(true);
   return(false);
}

int clsBot01::intSupportIdx()
{
   int out = 0;
   //if(PA.blNearSupport())     out = 1;
   if(PA_M30.blNearSupport()) out = 2;
   if(PA_H1.blNearSupport())  out = 3;
   if(PA_H4.blNearSupport())  out = 4;
   if(PA_D1.blNearSupport())  out = 5;
   return(out);
}

int clsBot01::intResistanceIdx(void)
{
   int out = 0;
   //if(PA.blNearResistance())     out = 1;
   if(PA_M30.blNearResistance()) out = 2;
   if(PA_H1.blNearResistance())  out = 3;
   if(PA_H4.blNearResistance())  out = 4;
   if(PA_D1.blNearResistance())  out = 5;
   return(out);
}

int clsBot01::intBullCandleIdx(void)
{
   int out = 0;
   if(PA.blFUCandle(1,0)     || PA.blFUCandle(1,1)     )  out = 1;
   if(PA_M30.blFUCandle(1,0) || PA_M30.blFUCandle(1,1) )  out = 2;
   if(PA_H1.blFUCandle(1,0)  || PA_H1.blFUCandle(1,1)  )  out = 3;
   if(PA_H4.blFUCandle(1,0)  || PA_H4.blFUCandle(1,1)  )  out = 4;
   if(PA_D1.blFUCandle(1,0)  || PA_D1.blFUCandle(1,1)  )  out = 5;
   return(out); 
}

int clsBot01::intBearCandleIdx(void)
{
   int out = 0;
   if(PA.blFUCandle(2,0)     || PA.blFUCandle(2,1)     ) out = 1;
   if(PA_M30.blFUCandle(2,0) || PA_M30.blFUCandle(2,1) ) out = 2;
   if(PA_H1.blFUCandle(2,0)  || PA_H1.blFUCandle(2,1)  )  out = 3;
   if(PA_H4.blFUCandle(2,0)  || PA_H4.blFUCandle(2,1)  )  out = 4;
   if(PA_D1.blFUCandle(2,0)  || PA_D1.blFUCandle(2,1)  )  out = 5;
   return(out); 
}

int clsBot01::intDailyDirection()
{
    int trend = 0;
    int sup_idx = intSupportIdx();
    int res_idx = intResistanceIdx();
    int bull_candle_idx = intBullCandleIdx();
    int bear_candle_idx = intBearCandleIdx();
    /*
    if(sup_idx != 0 && sup_idx >= 3)
    {
       if(bull_candle_idx >= 2 && bull_candle_idx != 0 && bull_candle_idx <= sup_idx) trend = 1;
    }
    if(res_idx != 0 && res_idx >= 3)
    {
       if(bear_candle_idx >= 2 && bear_candle_idx != 0 && bear_candle_idx <= res_idx) trend = 1;
    }
    */
    if(sup_idx != 0 )
    {
       if(bull_candle_idx != 0 && bull_candle_idx <= sup_idx) trend = 1;
    }
    if(res_idx != 0 )
    {
       if(bear_candle_idx != 0 && bear_candle_idx <= res_idx) trend = 1;
    }
    return(trend);
}

bool clsBot01::blDifficultSituationCheck(int type)
{
    for(int i = ArraySize(TRADE._terminal_trades) - 1; i >= 0; i--)
    {
         datetime closed_time = TRADE._terminal_trades[i]._order_closed_time;
         int day_allowed_elapsed = TimeDayOfWeek(closed_time) == 5  ? 4 : 1;
         int day_time_current = TimeDay(TimeCurrent());
         
         if(
              TRADE._terminal_trades[i]._active == false
              && TRADE._terminal_trades[i]._order_symbol == strSymbol   
           )
         {
               if(TimeCurrent() - TRADE._terminal_trades[i]._order_closed_time <=  10 * intBotPeriod * 60)
               {
                    if(type == 1)
                    {
                       if(TRADE._terminal_trades[i]._order_type == 0)
                       {
                           return(true);
                       }
                    }
                    if(type == 2)
                    {
                       if(TRADE._terminal_trades[i]._order_type == 1)
                       {
                           return(true);
                       }
                    }
               }
         }
    }
    
    return(false);
}


