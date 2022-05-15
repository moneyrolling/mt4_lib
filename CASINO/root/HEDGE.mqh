#include "TRADING_NEW.mqh"
#include "READ_WRITE.mqh"

extern double  Hedge_Profit_Multiplier = 100;
extern double  hedge_breakeven_start   = 10;
extern bool    hedge_use_breakeven = false;
extern int     hedge_max_allowed = 3;
extern int     hedge_assist_allowed = 3;
extern double  hedge_profit_multiplier = 100;
extern double  hedge_internal_solve_gap = 40;
extern double  hedge_avg_factor = 2;
extern double  hedge_surplus_gap = 5;
extern double  hedge_internal_power = 8;
extern double  hedge_range_threshold = 80;
extern double  hedge_reverse_threshold = 100;

class clsHedge 
{
      public:
                           clsHedge(clsTradeClass *TRADE_INPUT, clsMoneyManagement *MM_INPUT, string strInpSymbol, double base_lot, int tf);
                           ~clsHedge();
          string           strSymbol;
          int              intMagic;   // 0 simply signifying all
          void             Oninit();
          void             Updater();
          bool             blHedgeTag;
          bool             blHedgeBreakEvenTag;
          bool             blHedgePostReverseTag;
          bool             blHedgeInternalTag;
          bool             blHedgeRangingTag;
          bool             blHedgeNotEnoughTag;
          bool             blStrongHedgeTag;
          int              intHedgeInitiator;
          int              intLastHedgeIntitiator;
          void             HedgeStart(int type, int magic, bool additional_hedge = false);
          bool             blCanRestartHedge();
          bool             blPostBreakevenUnHedge();
          bool             blHedgeInternalTradeExist(int type, int magic, int count_allowed = 1);
          bool             blLRHedge();
          bool             blRangingCheck();
          bool             blNotEnoughHedge();
          bool             blSentimentSurge(int type);
          double           dblMinInternalPrice(int type, int magic);
          double           dblMaxInternalPrice(int type, int magic);
          double           dblAverageEntryPrices(int magic, int type);
          double           dblPredictedAvgPrice(int magic, int type);
          double           dblReversePredictedAvgPrice(int magic, int type);
          double           dblHedgeEntryPrice(int type);
          datetime         dtDifficultTime;
          datetime         dtRangeLastBuy;
          datetime         dtRangeLastSell;
          datetime         dtHedgeTime;
      
      protected:
         double            dblLastHedgePrice(int magic, int type);
         double            dblMaxLotPrice(int magic, int type);
         double            dblTotalSellLot();
         double            dblTotalBuyLot();
         double            dblMaxSellLot();
         double            dblMaxBuyLot();
         double            dblMaxDistance(int magic);
         double            dblMaxPrice(int type, int magic);
         double            dblMinPrice(int type, int magic);
         double            dblCloseProfitByTicket(int ticket);
         int               intDailyDirection();
         int               intTotalBuy();
         int               intTotalSell();
         datetime          dtMaxOpenTime();
         bool              blDuplicateTradeTagExist(int type, int magic, string strTag);
         bool              blHedgeTradeExist(int type, int magic);
         void              EnterBuy(TRADE_COMMAND &signal, bool reverse=false);
         void              EnterSell(TRADE_COMMAND &signal, bool reverse=false);
         void              CloseAll(int type=3);
         void              CloseReverseWithProfit(int reverse_direction, double inp_profit);
         void              HedgeClose();
         void              HedgeBreakEven();
         void              HedgeAssistBreakEven();
         void              HedgeZeroSlTp();
         void              PostHedgeReverseAdd();
         void              DeletePendingOrder();
         void              HedgeInternalSolve();
         void              HedgeAverageWay(int magic);
         void              HedgeReverseAverageWay(int magic);
         void              RangeDeal(int type);
         void              KillLastHedgeOverTime();
         
      
      private:
          
          
         clsTradeClass      *REF_TRADE;
         clsMoneyManagement *REF_MM;
         clsConfig          *TWRITE;
         double             dblBaseLot;
         int                intHedgePeriod;
         string             strHedgeFile;
         int                intHedgeCount;
         int                intHedgeAssistBECount;
         int                intHedgeStartCount;
         int                intHedgeInternalCount;
 };
 
 
 clsHedge::clsHedge(clsTradeClass *TRADE_INPUT, clsMoneyManagement *MM_INPUT, string strInpSymbol, double base_lot, int tf)
 {
      REF_TRADE  = TRADE_INPUT;
      REF_MM     = MM_INPUT;
      strSymbol  = strInpSymbol;
      dblBaseLot = base_lot;
      intHedgePeriod = tf;
      Oninit();
 }
 
 clsHedge::~clsHedge(){
     if(CheckPointer(TWRITE) == POINTER_DYNAMIC) delete TWRITE;
 }
 
 void clsHedge::Oninit(void)
 {
      TWRITE  = new clsConfig();
      if(!IsTesting())
     {
        strHedgeFile = strSymbol + "_hedge.csv";
        HEDGE_CONFIG hedge_new;
        TWRITE.ReadHedgeData(strHedgeFile,hedge_new);
        blHedgeTag = hedge_new.blHedgeTag;
        blHedgeBreakEvenTag = hedge_new.blHedgeBreakEven;
        intHedgeInitiator = hedge_new.intHedgeInitiator;
        //Alert("Current Hedge Tag is ",blHedgeTag);
        //Alert("Current Hedge Tag Breakeven is ",blHedgeBreakEvenTag);
        //Alert("Current Hedge Initiator is ",intHedgeInitiator);
        //ExpertRemove();
     }
 }
 
bool clsHedge::blSentimentSurge(int type)
{
    double atr_1 = iATR(strSymbol,PERIOD_M1,2,1);// NormalizeDouble(dblATR[0],4);//iATR(strSymbol,PERIOD_M1,2,1);
    double atr_2 = iATR(strSymbol,PERIOD_M1,2,2);//NormalizeDouble(dblATR[1],4);//iATR(strSymbol,PERIOD_M1,2,2);
    
    double close_1 = iClose(strSymbol,PERIOD_M1,1);
    double close_2 = iClose(strSymbol,PERIOD_M1,2);
    int    direction = close_1 > close_2 ? 1 : close_1 < close_2 ? 2 : 0;
    
    if(atr_2 == 0) return(false);
    
    //if(atr_1 > SurgePip * pips(strSymbol))
    if( atr_1 / atr_2 >= 2 && atr_1 >= 8 * pips(strSymbol) && atr_1 <= 2 * 8 * pips(strSymbol) )
    {
        Print("Sentiment Surge Checking");
        
        
        if(direction == 1 && type == 1)
        {
            Print("Bull Surging");
            return(true);
            //ExpertRemove();
        }
        if(direction == 2 && type == 2)
        {
            Print("Bear Surging");
            return(true);
            //ExpertRemove();
        }
        
    }
    return(false);
}


void clsHedge::KillLastHedgeOverTime()
{
    int type = intHedgeInitiator - 1;
    double hedge_price = 0;
    datetime hedge_time = 0;
    for(int i = ArraySize(REF_TRADE._terminal_trades) - 1; i >= 0; i--)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true      &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
             )
           { 
                  if(
                       REF_TRADE._terminal_trades[i]._order_type == type && 
                       REF_TRADE._terminal_trades[i]._hedge_trade == true
                    )
                  {
                         hedge_price = REF_TRADE._terminal_trades[i]._open_price;
                         hedge_time  = REF_TRADE._terminal_trades[i]._order_opened_time;
                         break;
                  }
           }
    }
    
    double max_sell_price = dblMaxPrice(2,intMagic);
    double min_sell_price = dblMinPrice(2,intMagic);
    double max_buy_price =  dblMaxPrice(1,intMagic);
    double min_buy_price =  dblMinPrice(1,intMagic);
    double max_price     =  MathMax(max_sell_price,max_buy_price);
    double min_price     =  MathMin(min_sell_price,min_buy_price);
    double total_lot     =  dblTotalBuyLot() + dblTotalSellLot();
    bool hedge_at_extreme;
    if(intHedgeInitiator == 1 && hedge_price != 0 && hedge_price == max_price) hedge_at_extreme = true;
    if(intHedgeInitiator == 2 && hedge_price != 0 && hedge_price == min_price) hedge_at_extreme = true;
    
    if(hedge_at_extreme) 
    {
         if(TimeCurrent() - hedge_time >= 1 * 60 * 60 && hedge_time != 0)
         {
             Print("Dragging with current profit of ",REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic));
             if(REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic) >= - 10 * total_lot)
             {
                Print("Drag too long, close trades");
                intLastDifficultDir = intHedgeInitiator == 1 ? 2 : 1;
                CloseAll();
             }
             /*
             if(blSentimentSurge(1) && intHedgeInitiator == 2) 
             {
                dtDifficultTime = TimeCurrent();
                CloseAll();
             }
             if(blSentimentSurge(2) && intHedgeInitiator == 1) 
             {
                dtDifficultTime = TimeCurrent();
                CloseAll();
             }
             */
         }
    }
}
 
void clsHedge::DeletePendingOrder()
{
    if(intHedgeInitiator == 1)
    {
          for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
          {
                 if(
                    REF_TRADE._terminal_trades[i]._active       == true      &&
                    REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
                    (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
                   )
                 { 
                      //we delete sell stop
                      if(REF_TRADE._terminal_trades[i]._order_type == 5)
                      {
                          if(OrderDelete(REF_TRADE._terminal_trades[i]._ticket_number))
                          {
                              REF_TRADE._terminal_trades[i]._active       = false;
                          }
                      }
                 }
          }
    }
    if(intHedgeInitiator == 2)
    {
          for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
          {
                 if(
                    REF_TRADE._terminal_trades[i]._active       == true      &&
                    REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
                    (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
                   )
                 { 
                      //we delete sell stop
                      if(REF_TRADE._terminal_trades[i]._order_type == 4)
                      {
                          if(OrderDelete(REF_TRADE._terminal_trades[i]._ticket_number))
                          {
                              REF_TRADE._terminal_trades[i]._active       = false;
                          }
                      }
                 }
          }
    }
} 

double clsHedge::dblReversePredictedAvgPrice(int magic, int type)
{
   double buy_avg_price  = dblAverageEntryPrices(magic,1);
   double sell_avg_price = dblAverageEntryPrices(magic,2);
   double total_buy_lot  = dblTotalBuyLot();
   double total_sell_lot = dblTotalSellLot();
   double lot_deficit    = type == 1 ? total_sell_lot - total_buy_lot : total_buy_lot - total_sell_lot;
   
   //this is a dangerous solution to counter add back position
   if(lot_deficit > 0) return(0);
   
   double cur_price      = type == 1 ? MarketInfo(strSymbol,MODE_ASK) : MarketInfo(strSymbol,MODE_BID);
   
   double buy_sum_price  = buy_avg_price * total_buy_lot;
   double sell_sum_price = sell_avg_price * total_sell_lot;
   
   lot_deficit = lot_deficit * hedge_avg_factor;
   
   double new_avg_price = 0;
   
   if(type == 1)
   {
       double denominator = (total_buy_lot + lot_deficit);
       if(denominator <= 0) return(0);
       new_avg_price = (buy_sum_price + (lot_deficit * cur_price)) / (total_buy_lot + lot_deficit);
   }
   if(type == 2)
   {
       double denominator = (total_sell_lot + lot_deficit);
       if(denominator <= 0) return(0);
       new_avg_price = (sell_sum_price + (lot_deficit * cur_price)) / (total_sell_lot + lot_deficit);
   }
   return(new_avg_price);  
}


double clsHedge::dblPredictedAvgPrice(int magic, int type)
{
   double buy_avg_price  = dblAverageEntryPrices(magic,1);
   double sell_avg_price = dblAverageEntryPrices(magic,2);
   double total_buy_lot  = dblTotalBuyLot();
   double total_sell_lot = dblTotalSellLot();
   double lot_deficit    = type == 1 ? total_sell_lot - total_buy_lot : total_buy_lot - total_sell_lot;
   
   if(lot_deficit <= 0) return(0);
   
   double cur_price      = type == 1 ? MarketInfo(strSymbol,MODE_ASK) : MarketInfo(strSymbol,MODE_BID);
   
   double buy_sum_price  = buy_avg_price * total_buy_lot;
   double sell_sum_price = sell_avg_price * total_sell_lot;
   
   lot_deficit = lot_deficit * hedge_avg_factor;
   
   double new_avg_price = 0;
   //new average price based on current market price with current lot deficit size
   if(type == 1)
   {
       new_avg_price = (buy_sum_price + (lot_deficit * cur_price)) / (total_buy_lot + lot_deficit);
   }
   if(type == 2)
   {
       new_avg_price = (sell_sum_price + (lot_deficit * cur_price)) / (total_sell_lot + lot_deficit);
   }
   return(new_avg_price);    
}



double clsHedge::dblMinPrice(int type, int magic)
{
   double min_price = DBL_MAX;
   int order_type = type - 1;
   for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
   {
        if(
           REF_TRADE._terminal_trades[i]._active       == true      &&
           REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
           (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
          )
        { 
              if(REF_TRADE._terminal_trades[i]._order_type == order_type)
              {
                   min_price = MathMin(min_price,REF_TRADE._terminal_trades[i]._entry);
              }
        }
   }
   if(min_price == DBL_MAX) min_price = 0;
   return(min_price);
}

double clsHedge::dblMaxPrice(int type, int magic)
{
   double max_price = DBL_MIN;
   int order_type = type - 1;
   int count = 0;
   for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
   {
        if(
           REF_TRADE._terminal_trades[i]._active       == true      &&
           REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
           (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
          )
        { 
              if(REF_TRADE._terminal_trades[i]._order_type == order_type)
              {
                   max_price = MathMax(max_price,REF_TRADE._terminal_trades[i]._entry);
                   count++;
              }
        }
   }
   if(max_price == DBL_MIN) max_price = 0;
   Print("Type is ",type," with  count of ",count);
   Print("Checking Max Output value is ",max_price);
   return(max_price);
}

double clsHedge::dblMaxBuyLot()
{
    double count = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true      &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
             )
           { 
               if(REF_TRADE._terminal_trades[i]._order_type == 0)
               {
                    count = MathMax(REF_TRADE._terminal_trades[i]._order_lot,count);
               }
           }
    }
    return(count);
}

double clsHedge::dblMaxSellLot()
{
    double count = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true      &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
             )
           { 
               if(REF_TRADE._terminal_trades[i]._order_type == 1)
               {
                    count = MathMax(REF_TRADE._terminal_trades[i]._order_lot,count);
               }
           }
    }
    return(count);
}

int clsHedge::intDailyDirection()
{
    
    int trend = 0;
    if(ArraySize(LR.dblClose_LR) == 0 || ArraySize(BIG_LR.dblClose_LR) == 0) return(trend);
    double ask = MarketInfo(strSymbol,MODE_ASK);
    double bid = MarketInfo(strSymbol,MODE_BID);
    int lr_trend  = LR.intCloseTrend;
    int big_trend = BIG_LR.intCloseTrend;
    
    double lr     = LR.dblClose_LR[0];
    double big_lr = LR.dblClose_LR[0];
    
    if(big_trend == 1 && ask < big_lr)
    {
         //we buy only once the support confirm and avoid trap on high side
         if(lr_trend == 2 && ask > lr) trend = 1;
         if(lr_trend == 1 && ask < lr) trend = 1;
    }
    if(big_trend == 2 && ask > big_lr)
    {
         //we sell only once the resistance confirm and avoid trap on low side
         if(lr_trend == 1 && ask < lr) trend = 2;
         if(lr_trend == 2 && ask > lr) trend = 2;
    }
    
    if(big_trend == 1 && lr_trend == 2) trend = 1;
    if(big_trend == 2 && lr_trend == 1) trend = 2;
    
    if( MathAbs(LR.dblClose_ms[0]) > 1 ) trend = 0; 
    
    return(trend);
    
    
}

 void clsHedge::PostHedgeReverseAdd()
 {
    if(blHedgePostReverseTag) return;
    double ask = MarketInfo(strSymbol,MODE_ASK);
    double bid = MarketInfo(strSymbol,MODE_BID);
    double buy_max_lot_price  = dblMaxLotPrice(intMagic,1);
    double sell_max_lot_price = dblMaxLotPrice(intMagic,2);
    double diff = MathAbs(buy_max_lot_price - sell_max_lot_price);
    
    double max_sell_price = dblMaxPrice(2,intMagic);
    double min_sell_price = dblMinPrice(2,intMagic);
    double max_buy_price = dblMaxPrice(1,intMagic);
    double min_buy_price = dblMinPrice(1,intMagic);
    
    double max_price = MathMax(max_buy_price,max_sell_price);
    double min_price = MathMin(min_buy_price,min_sell_price);
    
    int min_gap_factor = 50; //if gap more than this, we reverse add at mid point, else at extreme
    
    if(intHedgeInitiator == 2)// && PA.blMarketRanging)// (LR.dblClose_ms[0]/pips(strSymbol) < - 1))
    {
        //double mid_price     = max_buy_price - (max_buy_price - min_buy_price)/3;
        double mid_price     = min_buy_price - (min_buy_price - min_sell_price)/2;
        double cross_price   = mid_price;//dblMaxDistance(intMagic)/pips(strSymbol) >= 60 ? min_buy_price : max_buy_price;
        cross_price = max_buy_price + 15 * pips(strSymbol);
        
        double gap = (min_buy_price - max_sell_price)/pips(strSymbol);
        //if(gap < min_gap_factor) cross_price = max_buy_price;
        
        if(
              max_buy_price != 0 && min_buy_price != 0 &&
              bid >= cross_price 
          )
        /*
        if( 
            bid < buy_max_lot_price && bid > sell_max_lot_price &&
            bid >= buy_max_lot_price - (diff * 1 / 2) &&
            bid <= buy_max_lot_price - (diff * 1 / 3)
          )
        */  
        {
        
            //if(dblTotalSellLot() > dblTotalBuyLot())
            if(gap <= hedge_reverse_threshold)
            {
                if(PA.blFinalMarketRanging == false)
                {
                   double deficit_lot = dblTotalSellLot() - dblTotalBuyLot();
                   TRADE_COMMAND buy_command;
                   buy_command._magic = intMagic;
                   double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
                   double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
                   buy_command._lots = new_lot;
                   buy_command._hedge_assist_trade = true;
                   EnterBuy(buy_command);
                   intHedgeCount++;
                   intHedgeAssistBECount++;
                   blHedgePostReverseTag = true;
                }
                else
                {
                   double deficit_lot = dblTotalBuyLot() - dblTotalSellLot();
                   TRADE_COMMAND sell_command;
                   sell_command._magic = intMagic;
                   double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
                   double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
                   sell_command._lots = new_lot;
                   sell_command._hedge_assist_trade = true;
                   EnterSell(sell_command);
                   intHedgeCount++;
                   intHedgeAssistBECount++;
                   blHedgePostReverseTag = true;
                }
            }
        }
    }
    if(intHedgeInitiator == 1)// &&  PA.blMarketRanging)// (LR.dblClose_ms[0]/pips(strSymbol) > 1))
    { 
        //double mid_price     = max_sell_price - (max_sell_price - min_sell_price)/3;
        double mid_price     = max_buy_price - (max_buy_price - max_sell_price)/2;
        double cross_price   = mid_price;//dblMaxDistance(intMagic)/pips(strSymbol) >= 60 ? max_sell_price : min_sell_price;
        cross_price = min_sell_price - 10 * pips(strSymbol);;
        
        double gap = (min_sell_price - max_buy_price)/pips(strSymbol);
        //if(gap < min_gap_factor) cross_price = min_sell_price;
        /*
        if(TimeCurrent() >= D'2018.07.11 17:42')
        { 
           Print("Check");
           Print("Max Sell Price is ",max_sell_price);
           Print("Min Sell Price is ",min_sell_price);
           Print("Mid Price is ",mid_price);
           ExpertRemove();
        }
        */
        if(
              max_sell_price != 0 && min_sell_price != 0 &&
              bid <= cross_price 
          )
        {
            
            if(dblTotalBuyLot() > dblTotalSellLot())
            {
                //if(PA.blFinalMarketRanging == false)
                if(gap <= hedge_reverse_threshold)
                {
                   double deficit_lot = dblTotalBuyLot() - dblTotalSellLot();
                   TRADE_COMMAND sell_command;
                   sell_command._magic = intMagic;
                   double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
                   double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
                   sell_command._lots = new_lot;
                   sell_command._hedge_assist_trade = true;
                   EnterSell(sell_command);
                   intHedgeCount++;
                   intHedgeAssistBECount++;
                   blHedgePostReverseTag = true;
                }
                else
                {
                   double deficit_lot = dblTotalBuyLot() - dblTotalSellLot();
                   TRADE_COMMAND sell_command;
                   sell_command._magic = intMagic;
                   double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
                   double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
                   sell_command._lots = new_lot;
                   sell_command._hedge_assist_trade = true;
                   EnterSell(sell_command);
                   intHedgeCount++;
                   intHedgeAssistBECount++;
                   blHedgePostReverseTag = true;
                }
            }
        }
    }
      /*
      if(intHedgeInitiator == 1)
      {
           
           TRADE_COMMAND sell_command;
           sell_command._magic = intMagic;
           sell_command._lots = dblMaxBuyLot() * 0.8;// hedge_lot_ratio;dblMaxSellLot() * 1.5;//
           EnterSell(sell_command);
           //Print("Try to reverse sell");
           //ExpertRemove();
     }
     
      if(intHedgeInitiator == 2)
      {
           TRADE_COMMAND buy_command;
           buy_command._magic = intMagic;
           buy_command._lots =  dblMaxSellLot() * 0.8;////hedge_lot_ratio;dblMaxBuyLot() * 1.5;//
           EnterBuy(buy_command);
           //Print("Try to reverse buy");
           //ExpertRemove();
     }
     */
 }

bool clsHedge::blRangingCheck()
{
   double max_buy_price   = dblMaxPrice(1,intMagic);
   double max_sell_price  = dblMaxPrice(2,intMagic);
   double min_buy_price   = dblMinPrice(1,intMagic);
   double min_sell_price  = dblMinPrice(2,intMagic);
   
   double gap = MathMax(max_buy_price,max_sell_price)-MathMin(min_buy_price,min_sell_price);
   
   if(gap/pips(strSymbol) >= hedge_range_threshold) return(true);
   
   return(false);
}

bool clsHedge::blNotEnoughHedge()
{
   double total_buy  = dblTotalBuyLot();
   double total_sell = dblTotalSellLot();
   if(blHedgeTag)
   {
       if(!blHedgePostReverseTag)
       {
           if(intHedgeInitiator == 1 && total_buy != 0  && total_buy < total_sell) return(true);
           if(intHedgeInitiator == 2 && total_sell != 0 && total_buy > total_sell) return(true);
       }
   }
   return(false);
}

bool clsHedge::blLRHedge()
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

void clsHedge::RangeDeal(int type)
{
    double total_buy_lot  = dblTotalBuyLot();
    double total_sell_lot = dblTotalSellLot();
    
    double max_buy_price   = dblMaxPrice(1,intMagic);
    double max_sell_price  = dblMaxPrice(2,intMagic);
    double min_buy_price   = dblMinPrice(1,intMagic);
    double min_sell_price  = dblMinPrice(2,intMagic);
    
    double ask             = MarketInfo(strSymbol,MODE_ASK);
    double bid             = MarketInfo(strSymbol,MODE_BID);
   
    double max_price       = MathMax(max_buy_price,max_sell_price);
    double min_price       = MathMin(min_buy_price,min_sell_price);
    double gap = max_price - min_price;
    //double gap_pip = gap / strSymbol;
    double buy_profit  = REF_TRADE.dblTotalBuyProfit(strSymbol,intMagic);
    double sell_profit = REF_TRADE.dblTotalSellProfit(strSymbol,intMagic);
    
    
    if(intHedgeInitiator == 2)
    {
         //double deficit_lot    = total_buy_lot - total_sell_lot;
         //if(blHedgeNotEnoughTag) deficit_lot = total_sell_lot - total_buy_lot;
         double deficit_lot    = total_sell_lot - total_buy_lot;
         double profit_deficit = sell_profit + buy_profit;
           
         /*
         if(TimeCurrent() >= D'2022.04.12 17:55')
         {
             Print("A Buy Profit is ",buy_profit);
             Print("A Sell Profit is ",sell_profit);
             Print("A Profit Deficit is ",profit_deficit);
             Print("A Deficit lot is ",deficit_lot);
             Print("A Condition 1 is ",deficit_lot > 0);
             Print("A Condition 2 is ",min_price - ask >= 3 * pips(strSymbol));
             ExpertRemove();
         }
         */
         if(profit_deficit > 0) return; 
         double profit_to_cover = deficit_lot * 100;
         double dev_pip = intTotalBuy() * 3;
         double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
         double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
         //if(deficit_lot > 0 && min_price - ask >= dev_pip * pips(strSymbol) && MathAbs(profit_deficit) > profit_to_cover)
         if(deficit_lot < 0 &&  min_price - bid >= dev_pip * pips(strSymbol) && MathAbs(profit_deficit) > profit_to_cover)
         {
              //if( (gap)/pips(strSymbol) < 100)
              //if(new_lot / dblMaxBuyLot() >= 4.5)
              //if(new_lot / dblMaxBuyLot() < 1.9)
              /*
              if(PA.blMarketRanging == false)
              {
                  //Print("Place rehedge sell via range deal");
                  //HedgeStart(2,intMagic,true); //inital deal is hedge buu
                  Print("Place sell via range deal");
                  TRADE_COMMAND sell_command;
                  sell_command._magic = intMagic;
                  sell_command._lots = new_lot/2;
                  sell_command._hedge_internal_trade = true;
                  EnterSell(sell_command);
                  dtRangeLastSell = TimeCurrent();
                  intLastDifficultDir = 2;
              }
              */
              if(PA.blMarketRanging == false)
              {
                 Print("Place buy via range deal");
                 TRADE_COMMAND buy_command;
                 buy_command._magic = intMagic;
                 buy_command._lots = new_lot;
                 buy_command._hedge_internal_trade = true;
                 EnterBuy(buy_command);
                 dtRangeLastBuy = TimeCurrent();
                 intLastDifficultDir = 1;
              }
              
         }
    }
    
    //if(type == 2 || intHedgeInitiator == 1)
    if(intHedgeInitiator == 1)
    {
          //double deficit_lot    = total_sell_lot - total_buy_lot;
          //if(blHedgeNotEnoughTag) deficit_lot = total_buy_lot - total_sell_lot;
          double deficit_lot    = total_buy_lot - total_sell_lot;
          double profit_deficit = buy_profit + sell_profit;
          double dev_pip = intTotalSell() * 3;
          /*
          if(TimeCurrent() >= D'2022.04.12 17:55')
          {
             Print("B Buy Profit is ",buy_profit);
             Print("B Sell Profit is ",sell_profit);
             Print("B Profit Deficit is ",profit_deficit);
             Print("B Deficit lot is ",deficit_lot);
             Print("B Condition 1 is ",deficit_lot > 0);
             Print("B Condition 2 is ",bid - max_price >= 3 * pips(strSymbol));
             Print("Market Ranging status is ",PA.blMarketRanging);
             ExpertRemove();
          }
          */
         if(profit_deficit > 0) return; 
         double profit_to_cover = deficit_lot * 100;
         double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
         double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
         
         if(deficit_lot < 0 && bid - max_price >= dev_pip * pips(strSymbol) && MathAbs(profit_deficit) > profit_to_cover)
         {
              //if((gap)/pips(strSymbol) < 100)
              //if(new_lot / dblMaxSellLot() >= 4.5)
              //if(new_lot / dblMaxBuyLot() < 1.9)
              /*
              if(PA.blMarketRanging == false)
              {
                  Print("Place reverse buy via range deal");
                  //Print("Place buy via range deal");
                  TRADE_COMMAND buy_command;
                  buy_command._magic = intMagic;
                  buy_command._lots = new_lot/2;
                  buy_command._hedge_internal_trade = true;
                  EnterBuy(buy_command);
                  dtRangeLastBuy = TimeCurrent();
                  intLastDifficultDir = 1;
                  //HedgeStart(1,intMagic,true); //OLD
              }
              */
              if(PA.blMarketRanging == false)
              {
                 Print("Place sell via range deal");
                 TRADE_COMMAND sell_command;
                 sell_command._magic = intMagic;
                 sell_command._lots = new_lot;
                 sell_command._hedge_internal_trade = true;
                 EnterSell(sell_command);
                 dtRangeLastSell = TimeCurrent();
                 intLastDifficultDir = 2;
              }
              
         }
    }
}
 
 void clsHedge::Updater(void)
 {
      if(CheckPointer(REF_TRADE) != POINTER_DYNAMIC) return;
      if(blHedgeTag)
      {
          /*
          if(TimeCurrent() >= D'2021.06.04 04:58')
          {
              Print("Hello");
              ExpertRemove();
          }
          */
          // Part 1 : Resetting 
          if(
              (intTotalBuy() == 0 && intTotalSell() == 0) ||
              //intHedgeCount >= 5 ||
              (NormalizeDouble(dblTotalBuyLot(),2) == NormalizeDouble(dblTotalSellLot(),2))  ||
              //intHedgeInternalCount >= 3
              blPostBreakevenUnHedge() == true //||
              //(intHedgeInitiator == 1 && dblTotalSellLot() > dblTotalBuyLot()) ||
              //(intHedgeInitiator == 2 && dblTotalSellLot() < dblTotalBuyLot()) 
            ) 
          {
                 intLastHedgeIntitiator = intHedgeInitiator;
                 if((intTotalBuy() == 0 && intTotalSell() == 0)) intLastHedgeIntitiator = 0;
                 if(!blPostBreakevenUnHedge() && NormalizeDouble(dblTotalBuyLot(),2) == NormalizeDouble(dblTotalSellLot(),2)) 
                 {
                    CloseAll();
                    //if(TimeCurrent() >= D'2021.11.16 20:31') ExpertRemove();
                    //
                 }
                 blHedgeTag = false;
                 blHedgeBreakEvenTag = false;
                 blHedgeInternalTag = false;
                 blHedgePostReverseTag = false;
                 blHedgeRangingTag = false;
                 blHedgeNotEnoughTag = false;
                 blStrongHedgeTag = false;
                 intHedgeAssistBECount = 0;
                 intHedgeStartCount = 0;
                 intHedgeInitiator = 0;
                 intHedgeInternalCount = 0;
                 //ExpertRemove();
                 return;
          }
          
          if(!blHedgeRangingTag)
          {
             if(intHedgeStartCount <= hedge_max_allowed)
             {
                if(intHedgeInitiator == 1) HedgeStart(1,intMagic,true);
                if(intHedgeInitiator == 2) HedgeStart(2,intMagic,true);
             }
             
             HedgeClose();
             HedgeBreakEven();
             HedgeZeroSlTp(); 
             if(intHedgeAssistBECount <= hedge_assist_allowed)  
             {
                 PostHedgeReverseAdd();
             }
             if(blHedgePostReverseTag)KillLastHedgeOverTime();
             if(
                 (blHedgePostReverseTag && blRangingCheck()) ||
                 blNotEnoughHedge()
               )
             {
                 blHedgeRangingTag = true;
                 if(blNotEnoughHedge())
                 {
                    blHedgeNotEnoughTag = true;
                     //Print("Not enough hedge at ",TimeCurrent());
                     //ExpertRemove();
                 }
                 return;
             }
             /*
             if(TimeCurrent() >= D'2021.06.03 10:53')
             {
                 
                 double buy_profit  = REF_TRADE.dblTotalBuyProfit(strSymbol,intMagic);
                 double sell_profit = REF_TRADE.dblTotalSellProfit(strSymbol,intMagic);
                 Print("Total buy profit is ",buy_profit);
                 Print("Total sell profit is ",sell_profit);
                 ExpertRemove();
             }
             */
          }
          else
          {
             //ranging we can just add 1 vs 1 
             if(REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic) >= 0) CloseAll();
             /*
             if(!blHedgeNotEnoughTag && dblTotalBuyLot() > dblTotalSellLot() && TimeCurrent() - dtRangeLastSell > 1 * 60 * 60 && dtRangeLastSell != 0)
             {
                 HedgeStart(2,intMagic,true);
                 blHedgeBreakEvenTag = false;
                 blHedgeInternalTag = false;
                 blHedgePostReverseTag = false;
                 blHedgeRangingTag = false;
                 blHedgeNotEnoughTag = false;
                 blStrongHedgeTag = false;
                 //Print("Rehedge Sell here");
                 //ExpertRemove();
             }
             if(!blHedgeNotEnoughTag && dblTotalSellLot() > dblTotalBuyLot() && TimeCurrent() - dtRangeLastBuy > 1 * 60 * 60 && dtRangeLastBuy != 0)
             {
                 HedgeStart(1,intMagic,true);
                 blHedgeBreakEvenTag = false;
                 blHedgeInternalTag = false;
                 blHedgePostReverseTag = false;
                 blHedgeRangingTag = false;
                 blHedgeNotEnoughTag = false;
                 blStrongHedgeTag = false;
                 //Print("Rehedge Buy here");
                 //ExpertRemove();
             }
             */
             RangeDeal(1);
             RangeDeal(2);
          }
          
      }
      else
      {
           //non-hedge status
      }
 }
 

 
bool clsHedge::blCanRestartHedge(void)
{
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if
            (
              REF_TRADE._terminal_trades[i]._active       == true       &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol  &&
              (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0) &&
              REF_TRADE._terminal_trades[i]._hedge_trade  == true
             )
           {
                if(intHedgeInitiator - 1 == REF_TRADE._terminal_trades[i]._order_type)
                {
                    return(false);
                }
           }
    }
    return(true);
}
 
datetime clsHedge::dtMaxOpenTime()
{
    datetime open_time = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if
            (
              REF_TRADE._terminal_trades[i]._active       == true       &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol  &&
              (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
             )
           {
                 open_time = MathMax(open_time,REF_TRADE._terminal_trades[i]._order_opened_time);
           }
    }
    return(open_time);
}

void clsHedge::CloseAll(int type=3)
{
     if(type == 1 || type == 3)
     {
        TRADE_COMMAND BUY_CLOSE;
        BUY_CLOSE._action = MODE_TCLSE;
        BUY_CLOSE._symbol = this.strSymbol;
        BUY_CLOSE._order_type = 0;
        BUY_CLOSE._magic  = 0;
        REF_TRADE.CloseTradeAction(BUY_CLOSE);
     }
     if(type == 2 || type == 3)
     {
        TRADE_COMMAND SELL_CLOSE;
        SELL_CLOSE._action = MODE_TCLSE;
        SELL_CLOSE._symbol = this.strSymbol;
        SELL_CLOSE._order_type = 1;
        SELL_CLOSE._magic  = 0;
        REF_TRADE.CloseTradeAction(SELL_CLOSE);
     }
}
 
 void clsHedge::HedgeClose()
{
    double total_buy  = dblTotalBuyLot();
    double total_sell = dblTotalSellLot();
    double sum_lot    = total_buy + total_sell;
    /*
    if(total_buy > 0 && total_sell > 0)
    {
       double profit_to_close = sum_lot * Hedge_Profit_Multiplier;
       if(sum_lot >= 50 * dblBaseLot ) profit_to_close = sum_lot * 10;
       //if(sum_lot >= 5 ) profit_to_close = sum_lot * 10;
       if(
            (blHedgeTag && sum_lot < 0) ||
            (blHedgeTag && (TimeCurrent() - dtMaxOpenTime() >= 30 * intHedgePeriod) && REF_MM.dblPseudoEquity >= REF_MM.dblPseudoAccountBalance(strSymbol))
          ) 
       {  
            profit_to_close = 0;
       }
       if
       (
         //(REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic) > profit_to_close) //||
         REF_MM.dblPseudoEquity >= REF_MM.dblMaxPseudoEquity
       )
       {
           CloseAll();
           Print("Hedge All trades closed successfully");
           //ExpertRemove();
       }
    }
    */
    if(blHedgeTag)
    {
        //if(REF_MM.dblPseudoEquity >= REF_MM.dblMaxPseudoEquity + 1)
        double profit_to_close = sum_lot * 10;
        if(REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic) > profit_to_close)
        {
           if(intHedgeInitiator == 1)
           {
               if(dblTotalBuyLot() > dblBaseLot || dblTotalBuyLot() == 0)
               {
                   //hedge being reversed
                   //if(REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic) > 1)
                   if(dblTotalSellLot() > dblTotalBuyLot())
                   {
                       CloseAll();
                       Print("Hedge All trades closed successfully via reversed way");
                       intHedgeCount = 0;
                   }
                   else
                   {
                      CloseAll();
                      Print("Hedge All trades closed successfully via breakout way");
                      intHedgeCount = 0;
                      //Print("Close time is ",TimeCurrent());
                      //ExpertRemove();
                   }
               }
               
           }
           if(intHedgeInitiator == 2)
           {
               if(dblTotalSellLot() > dblBaseLot  || dblTotalSellLot() == 0)
               {
                   //hedge being reversed
                   //if(REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic) > 1)
                   if(dblTotalBuyLot() > dblTotalSellLot())
                   {
                       CloseAll();
                       Print("Hedge All trades closed successfully via reversed way");
                   }
                   else
                   {
                       CloseAll();
                       Print("Hedge All trades closed successfully via breakout way");
                   }
               }
           }
        }
    }
}

double clsHedge::dblCloseProfitByTicket(int ticket)
{
    double profit = 0;
    for(int i = ArraySize(REF_TRADE._terminal_trades) - 1; i >= 0; i--)
    {
         if
            (
              (REF_TRADE._terminal_trades[i]._ticket_number == ticket )
             )
        {
            profit = REF_TRADE._terminal_trades[i]._order_profit + REF_TRADE._terminal_trades[i]._order_comission + REF_TRADE._terminal_trades[i]._order_swap;
            break;
        }
    }
    return(profit);
}

void clsHedge::CloseReverseWithProfit(int reverse_direction, double inp_profit)
{
    int order_type = reverse_direction - 1;
    double profit_to_close = inp_profit;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    //for(int i = ArraySize(REF_TRADE._terminal_trades) - 1; i >= 0; i--)
    {
          if(
               REF_TRADE._terminal_trades[i]._active == true &&
               REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
               (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0) &&
               REF_TRADE._terminal_trades[i]._order_type == order_type
            )
          {
               double trade_profit = REF_TRADE._terminal_trades[i]._order_profit + REF_TRADE._terminal_trades[i]._order_comission + REF_TRADE._terminal_trades[i]._order_swap;
               double close_price  = REF_TRADE._terminal_trades[i]._order_type == 0 ? MarketInfo(strSymbol,MODE_BID) : MarketInfo(strSymbol,MODE_ASK);
               if(trade_profit > 0) continue;
               if(profit_to_close >= MathAbs(trade_profit))
               {
                    if(OrderClose(REF_TRADE._terminal_trades[i]._ticket_number,REF_TRADE._terminal_trades[i]._order_lot,close_price,slippage))
                    {
                          REF_TRADE._terminal_trades[i]._active = false;
                          profit_to_close += trade_profit;
                          //Print("Close ticket is ",REF_TRADE._terminal_trades[i]._ticket_number);
                          //Print("Left over profit is ",profit_to_close);
                          //ExpertRemove();
                    }
               }
          }
   }
}

double clsHedge::dblMaxDistance(int magic)
{
    double value = 0;
    double max_price = DBL_MIN;
    double min_price = DBL_MAX;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
        if(
           REF_TRADE._terminal_trades[i]._active       == true      &&
           REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
           REF_TRADE._terminal_trades[i]._magic_number == magic
          )
          {
               max_price = MathMax(max_price,REF_TRADE._terminal_trades[i]._entry);
               min_price = MathMax(min_price,REF_TRADE._terminal_trades[i]._entry);
          }
    }
    if(max_price != DBL_MIN && min_price != DBL_MAX)
    {
        value = MathAbs(max_price - min_price) / pips(strSymbol);
    }
    return(value);
}

bool clsHedge::blPostBreakevenUnHedge()
{
     for(int i = ArraySize(REF_TRADE._terminal_trades) - 1; i >= 0; i--)
     {
          if(
               REF_TRADE._terminal_trades[i]._active == false &&
               REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
               (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0) &&
               REF_TRADE._terminal_trades[i]._hedge_trade  == true &&
               REF_TRADE._terminal_trades[i]._breakeven_tag == true
            )
          {
               datetime order_close_time = REF_TRADE._terminal_trades[i]._order_closed_time;
               if(
                    TimeCurrent() - order_close_time >= 120 * 60 //&& 
                    //TimeCurrent() - order_close_time <= 1 * 60
                 )
               {
                  //Print("Detected Post Hedge Breakeven Trade");
                  //ExpertRemove();
                  return(true);
               }
               
          }
          break;
     }
     return(false);
}

void clsHedge::HedgeAssistBreakEven()
{
    double ask = MarketInfo(strSymbol,MODE_ASK);
    double bid = MarketInfo(strSymbol,MODE_BID);
    
    if(blHedgeTag == true)
    {
       //bull initiating the hedge
       for(int i = ArraySize(REF_TRADE._terminal_trades) - 1; i >= 0; i--)
       {
             if(
                  REF_TRADE._terminal_trades[i]._active == true &&
                  REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
                  (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0) &&
                  REF_TRADE._terminal_trades[i]._hedge_assist_trade  == true 
               )
              {
                    if(intHedgeInitiator == 1)
                    {
                        if(REF_TRADE._terminal_trades[i]._order_type == OP_SELL)
                        {
                              
                           if(REF_TRADE._terminal_trades[i]._entry - ask >= hedge_breakeven_start * pips(strSymbol))
                           {
                              if(REF_TRADE._terminal_trades[i]._stop_loss > REF_TRADE._terminal_trades[i]._entry || REF_TRADE._terminal_trades[i]._stop_loss == 0)
                             {
                                   double new_tp = REF_TRADE._terminal_trades[i]._take_profit < ask ? REF_TRADE._terminal_trades[i]._take_profit : 0;
                                   double new_sl = REF_TRADE._terminal_trades[i]._entry  - 1 * pips(strSymbol);
                                   if(OrderModify(REF_TRADE._terminal_trades[i]._ticket_number,
                                                  REF_TRADE._terminal_trades[i]._entry,
                                                  new_sl,
                                                  new_tp,
                                                  REF_TRADE._terminal_trades[i]._order_expiry
                                                 )
                                     )
                                  { 
                                        
                                        REF_TRADE._terminal_trades[i]._stop_loss = new_sl;
                                        
                                  }
                                                 
                             }
                           }
                        }
                    }
                    if(intHedgeInitiator == 2)
                    {
                       if(REF_TRADE._terminal_trades[i]._order_type == OP_BUY)
                          {
                             if(bid - REF_TRADE._terminal_trades[i]._entry >= hedge_breakeven_start * pips(strSymbol))
                             {
                             
                                    if(REF_TRADE._terminal_trades[i]._stop_loss < REF_TRADE._terminal_trades[i]._entry || REF_TRADE._terminal_trades[i]._stop_loss == 0)
                                        {
                                               double new_tp = REF_TRADE._terminal_trades[i]._take_profit > bid ? REF_TRADE._terminal_trades[i]._take_profit : 0;
                                               double new_sl = REF_TRADE._terminal_trades[i]._entry + 1 * pips(strSymbol);
                                               if(OrderModify(REF_TRADE._terminal_trades[i]._ticket_number,
                                                              REF_TRADE._terminal_trades[i]._entry,
                                                              new_sl,
                                                              new_tp,
                                                              REF_TRADE._terminal_trades[i]._order_expiry
                                                             )
                                                 )
                                              {
                                                    REF_TRADE._terminal_trades[i]._stop_loss = new_sl;
                                              }
                                                              
                                        }
                                 
                             }
                          }
                    }
              }
       }
    }
    
}

double clsHedge::dblHedgeEntryPrice(int type)
{
     int order_type = type - 1;
     double price = type == 1 ? DBL_MIN : DBL_MAX; 
     
     for(int i = ArraySize(REF_TRADE._terminal_trades) - 1; i >= 0; i--)
     {
          if(
               REF_TRADE._terminal_trades[i]._active == true &&
               REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
               (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0) &&
               REF_TRADE._terminal_trades[i]._hedge_trade  == true &&
               REF_TRADE._terminal_trades[i]._order_type == type
            )
           { 
                if(type == 1) price = MathMax(price,REF_TRADE._terminal_trades[i]._open_price);  
                if(type == 2) price = MathMin(price,REF_TRADE._terminal_trades[i]._open_price);          
           }
     }
     return(price);
}

void clsHedge::HedgeBreakEven()
{
     double ask = MarketInfo(strSymbol,MODE_ASK);
     double bid = MarketInfo(strSymbol,MODE_BID);
     double total_buy_lot  = dblTotalBuyLot();
     double total_sell_lot = dblTotalSellLot();
     
     if(blHedgeTag == true)
     {
          //bull initiating the hedge
          for(int i = ArraySize(REF_TRADE._terminal_trades) - 1; i >= 0; i--)
          {
                if(
                     REF_TRADE._terminal_trades[i]._active == true &&
                     REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
                     (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0) &&
                     REF_TRADE._terminal_trades[i]._hedge_trade  == true &&
                     REF_TRADE._terminal_trades[i]._breakeven_tag == false
                  )
                 {
                        if(intHedgeInitiator == 1)
                        {
                        
                           if(REF_TRADE._terminal_trades[i]._order_type == OP_BUY)
                           {
                                 if(bid - REF_TRADE._terminal_trades[i]._entry >= hedge_breakeven_start * pips(strSymbol))
                                 {
                                        if(total_buy_lot >= total_sell_lot)
                                        {
                                           if(hedge_use_breakeven)
                                           {
                                              //PREPARE BREAKEVEN
                                              if(REF_TRADE._terminal_trades[i]._stop_loss < REF_TRADE._terminal_trades[i]._entry || REF_TRADE._terminal_trades[i]._stop_loss == 0)
                                              {
                                                     double hedge_max_entry = dblHedgeEntryPrice(1);
                                                     double new_tp = REF_TRADE._terminal_trades[i]._take_profit > bid ? REF_TRADE._terminal_trades[i]._take_profit : 0;
                                                     double new_sl = REF_TRADE._terminal_trades[i]._entry + 1 * pips(strSymbol);
                                                     //double new_sl = hedge_max_entry + 1 * pips(strSymbol);
                                                     if(OrderModify(REF_TRADE._terminal_trades[i]._ticket_number,
                                                                    REF_TRADE._terminal_trades[i]._entry,
                                                                    new_sl,
                                                                    new_tp,
                                                                    REF_TRADE._terminal_trades[i]._order_expiry
                                                                   )
                                                       )
                                                    {
                                                          REF_TRADE._terminal_trades[i]._stop_loss = new_sl;
                                                          REF_TRADE._terminal_trades[i]._breakeven_tag = true;
                                                          
                                                          if(REF_TRADE._terminal_trades[i]._order_lot > dblBaseLot) blHedgeBreakEvenTag = True;
                                                          DeletePendingOrder(); //delete the pending stop order at reverse side
                                                    }
                                                                    
                                              }
                                            }
                                           
                                       }
                                       else
                                       {
                                            HedgeStart(1,intMagic,true);
                                            
                                            intHedgeCount++;
                                            //Print("Here");
                                            //ExpertRemove();
                                            /*
                                            if(OrderClose(REF_TRADE._terminal_trades[i]._ticket_number,REF_TRADE._terminal_trades[i]._order_lot,bid,slippage))
                                            {
                                                REF_TRADE._terminal_trades[i]._active = false;
                                                blHedgeTag = false;
                                                intHedgeInitiator = 0;
                                                blHedgeBreakEvenTag = false;
                                                double close_profit = dblCloseProfitByTicket(REF_TRADE._terminal_trades[i]._ticket_number);
                                                Print("Profit Close ticket is ",REF_TRADE._terminal_trades[i]._ticket_number);
                                                Print("Profit closed is ",close_profit);
                                                //CloseReverseWithProfit(2,close_profit);
                                                //if(dblMaxDistance(intMagic) != 0 && dblMaxDistance(intMagic) < 100 * pips(strSymbol))
                                                //{
                                                    HedgeStart(1,intMagic,true);
                                                
                                                
                                                if(OrderSelect(OrdersTotal()-1,SELECT_BY_POS) && OrderTicket() >= 14)
                                                //if(TimeCurrent() > D'2010.04.15 09:56')
                                                {
                                                     Print("C");
                                                     Print("Hedge Status is ",blHedgeTag);
                                                     Print("Hedge Status Changed at ",OrderTicket());
                                                     ExpertRemove();
                                                }
                                                
                                            }
                                            */
                                       }
                                 }
                                 
                                 
                           }
                       }
                       if(intHedgeInitiator == 2)
                        {
                           if(REF_TRADE._terminal_trades[i]._order_type == OP_SELL)
                           {
                             if(REF_TRADE._terminal_trades[i]._entry - ask >= hedge_breakeven_start * pips(strSymbol))
                             {
                                
                                        if(total_sell_lot >= total_buy_lot)
                                        {
                                           if(hedge_use_breakeven)
                                           {
                                              //PREPARE BREAKEVEN
                                              double hedge_max_entry = dblHedgeEntryPrice(2);
                                              double new_tp = REF_TRADE._terminal_trades[i]._take_profit < ask ? REF_TRADE._terminal_trades[i]._take_profit : 0;
                                              double new_sl = REF_TRADE._terminal_trades[i]._entry  - 1 * pips(strSymbol);
                                              //double new_sl = hedge_max_entry - 1 * pips(strSymbol);
                                              if(
                                                   (REF_TRADE._terminal_trades[i]._stop_loss > REF_TRADE._terminal_trades[i]._entry || REF_TRADE._terminal_trades[i]._stop_loss == 0) 
                                                )
                                              {
                                                     
                                                     if(OrderModify(REF_TRADE._terminal_trades[i]._ticket_number,
                                                                    REF_TRADE._terminal_trades[i]._entry,
                                                                    new_sl,
                                                                    new_tp,
                                                                    REF_TRADE._terminal_trades[i]._order_expiry
                                                                   )
                                                       )
                                                    { 
                                                          
                                                          REF_TRADE._terminal_trades[i]._stop_loss = new_sl;
                                                          REF_TRADE._terminal_trades[i]._breakeven_tag = true;
                                                          if(REF_TRADE._terminal_trades[i]._order_lot > dblBaseLot) {blHedgeBreakEvenTag = True;}
                                                          DeletePendingOrder(); //delete the pending stop order at reverse side
                                                          
                                                    }
                                                    else
                                                    {
                                                          Alert("Failed to modify sell hedge breakeven of ticket ",REF_TRADE._terminal_trades[i]._ticket_number);
                                                          //ExpertRemove();
                                                    }
                                                                    
                                              }
                                           }
                                           
                                       }
                                       else
                                       {
                                            HedgeStart(2,intMagic,true);
                                            intHedgeCount++;
                                            /*
                                            if(OrderClose(REF_TRADE._terminal_trades[i]._ticket_number,REF_TRADE._terminal_trades[i]._order_lot,ask,slippage))
                                            {
                                                REF_TRADE._terminal_trades[i]._active = false;
                                                blHedgeTag = false;
                                                intHedgeInitiator = 0;
                                                blHedgeBreakEvenTag = false;
                                                double close_profit = dblCloseProfitByTicket(REF_TRADE._terminal_trades[i]._ticket_number);
                                                Print("Profit Close ticket is ",REF_TRADE._terminal_trades[i]._ticket_number);
                                                Print("Profit closed is ",close_profit);
                                                //CloseReverseWithProfit(1,close_profit);
                                                //if(dblMaxDistance(intMagic) != 0 && dblMaxDistance(intMagic) < 100 * pips(strSymbol))
                                                //{
                                                    HedgeStart(2,intMagic,true);
                                                //}
                                                //HedgeStart(2,intMagic,true);
                                            }
                                            */
                                       }
                                // }
                               }
                           }
                       }
                 }
          }
         
     }
}

void clsHedge::HedgeZeroSlTp()
{
   for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
   {
          if(
               REF_TRADE._terminal_trades[i]._active == true &&
               REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
               (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0) //&&
               //TRADE._terminal_trades[i]._order_type   == type
            )
           {
               if(REF_TRADE._terminal_trades[i]._hedge_trade || REF_TRADE._terminal_trades[i]._hedge_assist_trade ) continue;
                   if(REF_TRADE._terminal_trades[i]._stop_loss != 0 || REF_TRADE._terminal_trades[i]._take_profit != 0)
                   {
                        if(OrderModify(
                                          REF_TRADE._terminal_trades[i]._ticket_number,
                                          REF_TRADE._terminal_trades[i]._entry,
                                          0,
                                          0,
                                          REF_TRADE._terminal_trades[i]._order_expiry
                                      )
                          )
                        {
                              REF_TRADE._terminal_trades[i]._stop_loss = 0;
                              REF_TRADE._terminal_trades[i]._take_profit = 0;
                        }
                   }
           }
   }
}

double clsHedge::dblAverageEntryPrices(int magic, int type)
{
    type = type - 1;
    //OUTPUT : 0 / Entry Price
    double sum_entry = 0;
    double total_entry = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true      &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              REF_TRADE._terminal_trades[i]._order_type   == type &&
              REF_TRADE._terminal_trades[i]._magic_number == magic
             )
           {
                 sum_entry += REF_TRADE._terminal_trades[i]._entry;// * REF_TRADE._terminal_trades[i]._order_lot;
                 total_entry ++;// REF_TRADE._terminal_trades[i]._order_lot;
           }
    }
    if(total_entry==0) return(0);
    return(sum_entry/total_entry);
}
 
 double clsHedge::dblTotalBuyLot()
{
    double count = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true      &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
             )
           { 
               if(REF_TRADE._terminal_trades[i]._order_type == 0 || REF_TRADE._terminal_trades[i]._order_type == 2 || REF_TRADE._terminal_trades[i]._order_type == 4)
               {
                    count += REF_TRADE._terminal_trades[i]._order_lot;
               }
           }
    }
    return(count);
}

double clsHedge::dblTotalSellLot()
{
    double count = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true      &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (REF_TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
             )
           { 
               if(REF_TRADE._terminal_trades[i]._order_type == 1 || REF_TRADE._terminal_trades[i]._order_type == 3 || REF_TRADE._terminal_trades[i]._order_type == 5)
               {
                    count += REF_TRADE._terminal_trades[i]._order_lot;
               }
           }
    }
    return(count);
}

int clsHedge::intTotalBuy()
{
    int count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
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

int clsHedge::intTotalSell()
{
    int count = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (TRADE._terminal_trades[i]._magic_number == intMagic || intMagic == 0)
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

double clsHedge::dblMaxLotPrice(int magic, int type)
{
    type = type - 1;
    double max_lot = DBL_MIN;
    double max_lot_entry = 0;
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true       &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol  &&
              REF_TRADE._terminal_trades[i]._order_type   == type &&
              (REF_TRADE._terminal_trades[i]._magic_number == magic || intMagic == 0)
             )
           {
                max_lot = MathMax(max_lot,REF_TRADE._terminal_trades[i]._order_lot);
                max_lot_entry = max_lot == REF_TRADE._terminal_trades[i]._order_lot ? REF_TRADE._terminal_trades[i]._entry : max_lot_entry;
           }
    }
    return(max_lot_entry);
}

double clsHedge::dblLastHedgePrice(int magic, int type)
{
   //TYPE 1 = BUY HEDGE; TYPE 2 = SELL HEDGE
   type = type - 1;
   double value = type == 0 ? DBL_MIN : DBL_MAX; // if buy hedge we seek for highest, while sell hedge we seek for lowest
   for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
   {
         if(
              REF_TRADE._terminal_trades[i]._active       == true       &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol  &&
              REF_TRADE._terminal_trades[i]._order_type   == type       &&
              (REF_TRADE._terminal_trades[i]._magic_number == magic || intMagic == 0)     &&
              REF_TRADE._terminal_trades[i]._hedge_trade  == true
             )
           {
                if(type == 0) value = MathMax(value,REF_TRADE._terminal_trades[i]._entry);
                if(type == 1) value = MathMin(value,REF_TRADE._terminal_trades[i]._entry);
           }
   }
   if(value == DBL_MIN || value == DBL_MAX) value = 0;
   return(value);
}

bool clsHedge::blDuplicateTradeTagExist(int type, int magic, string strTag)
{
    type = type - 1;
    
    for(int i = 0; i < ArraySize(REF_TRADE._terminal_trades); i++)
    {
           if(
              REF_TRADE._terminal_trades[i]._active       == true      &&
              REF_TRADE._terminal_trades[i]._order_symbol == strSymbol &&
              (REF_TRADE._terminal_trades[i]._magic_number == magic  || intMagic == 0) &&
              REF_TRADE._terminal_trades[i]._order_type   == type      &&
              REF_TRADE._terminal_trades[i]._trade_entry_tag == strTag
             )
           {
               return(true);
           }
    }
    return(false);
}

bool clsHedge::blHedgeInternalTradeExist(int type, int magic, int count_allowed = 1)
{
    type = type - 1;
    //always use extreme both side price as tag
    double buy_max_price  = dblMaxPrice(1,magic);
    double sell_min_price = dblMinPrice(2,magic);
    double buy_lot        = NormalizeDouble(dblTotalBuyLot(),2);
    double sell_lot       = NormalizeDouble(dblTotalSellLot(),2);
    string tag = (string)buy_max_price + (string)sell_min_price;// + (string)buy_lot + (string)sell_lot;
    
    int count = 0;
    
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
          if(
               TRADE._terminal_trades[i]._active == true &&
               TRADE._terminal_trades[i]._order_symbol == strSymbol &&
               (TRADE._terminal_trades[i]._magic_number == magic  || intMagic == 0)&&
               TRADE._terminal_trades[i]._order_type   == type &&
               TRADE._terminal_trades[i]._trade_entry_tag  == tag
            )
           {
                if(TRADE._terminal_trades[i]._hedge_internal_trade == true)
                {
                       count++;
                }
           }
    }
    if(count >= count_allowed) return(true);
    return(false);
}


bool clsHedge::blHedgeTradeExist(int type, int magic)
{
   double last_hedge_price = dblLastHedgePrice(magic,type);
   if(last_hedge_price != 0)
   {
       if(type == 1) 
       {
           //meaning we are BUY hedge trade entered before, but being changed status and the latest sell trade go higher
           //so we allow hedge again
           if(dblMaxLotPrice(magic,2) > last_hedge_price) return(false);
       }
       if(type == 2) 
       {
           //meaning we are SELL hedge trade entered before, but being changed status and the latest buy trade go lower
           //so we allow hedge again
           if(dblMaxLotPrice(magic,1) < last_hedge_price) return(false);
       }
   }
   type = type - 1;
   for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
   {
          if(
               TRADE._terminal_trades[i]._active == true &&
               TRADE._terminal_trades[i]._order_symbol == strSymbol &&
               (TRADE._terminal_trades[i]._magic_number == magic  || intMagic == 0)&&
               TRADE._terminal_trades[i]._order_type   == type
            )
           {
                if(TRADE._terminal_trades[i]._hedge_trade == true)
                {
                     Print("Hedge Trade Ticket is ",TRADE._terminal_trades[i]._ticket_number);
                     return(true);
                }
           }
   }
   return(false);
}

void clsHedge::HedgeReverseAverageWay(int magic)
{
   //DANGEROUS AS WE ENTER IN UNFAVOURABLE PLACE
   if(!blHedgeTag) return;
   double buy_avg_price  = dblAverageEntryPrices(magic,1);
   double sell_avg_price = dblAverageEntryPrices(magic,2);
   
   double post_rev_buy_predicted_price  = dblPredictedAvgPrice(magic,2);
   double post_rev_sell_predicted_price = dblPredictedAvgPrice(magic,1);
   
   double total_buy_lot  = dblTotalBuyLot();
   double total_sell_lot = dblTotalSellLot();
   
   double sell_max_price = dblMaxPrice(2,magic);
   double buy_min_price  = dblMinPrice(1,magic);
   
   double ask = MarketInfo(strSymbol,MODE_ASK);
   double bid = MarketInfo(strSymbol,MODE_BID);
   
   if(buy_avg_price == 0 || sell_avg_price == 0) return;
   
   if(buy_avg_price > sell_avg_price)
   {
        if(post_rev_sell_predicted_price > buy_avg_price && post_rev_sell_predicted_price != 0 && buy_avg_price < bid )
        {
              double deficit_lot = total_buy_lot - total_sell_lot;
              //if(deficit_lot >= 0 || deficit_lot <= -1) return;
              if(deficit_lot >= 0 ) return;
              
              if(sell_max_price != 0 && bid > sell_max_price + hedge_surplus_gap * pips(strSymbol))
              {
                 
                 TRADE_COMMAND sell_command;
                 sell_command._magic = intMagic;
                 sell_command._lots = MathAbs(deficit_lot) * hedge_avg_factor;// (1 + (0.5 * dist_multp));
                 sell_command._lots = NormalizeDouble(sell_command._lots,2);
                 sell_command._hedge_internal_trade = true;
                 EnterSell(sell_command);
                 
              }
        }
        if(post_rev_buy_predicted_price < sell_avg_price && post_rev_buy_predicted_price != 0 && sell_avg_price > ask )
        {
              double deficit_lot = total_sell_lot - total_buy_lot;
              //if(deficit_lot >= 0 || deficit_lot <= -1) return;
              if(deficit_lot >= 0 ) return;
              
              
              if(buy_min_price != 0 && ask < buy_min_price - hedge_surplus_gap * pips(strSymbol))
              {
                 TRADE_COMMAND buy_command;
                 buy_command._magic = intMagic;
                 buy_command._lots = MathAbs(deficit_lot) * hedge_avg_factor;// (1 + (0.5 * dist_multp));
                 buy_command._lots = NormalizeDouble(buy_command._lots,2);
                 buy_command._hedge_internal_trade = true;
                 EnterBuy(buy_command);
                 
              }
        }
   }
}

void clsHedge::HedgeAverageWay(int magic)
{
   if(!blHedgeTag) return;
   double buy_avg_price  = dblAverageEntryPrices(magic,1);
   double sell_avg_price = dblAverageEntryPrices(magic,2);
   
   double buy_predicted_price  = dblPredictedAvgPrice(magic,1);
   double sell_predicted_price = dblPredictedAvgPrice(magic,2);
   
   double total_buy_lot  = dblTotalBuyLot();
   double total_sell_lot = dblTotalSellLot();
   
   double ask = MarketInfo(strSymbol,MODE_ASK);
   double bid = MarketInfo(strSymbol,MODE_BID);
   
   if(buy_avg_price == 0 || sell_avg_price == 0) return;
   
   if(buy_avg_price > sell_avg_price)
   {
        if(buy_predicted_price < sell_avg_price && buy_predicted_price != 0)// && sell_avg_price > bid + 10 * pips(strSymbol))
        {
              double deficit_lot = total_sell_lot - total_buy_lot;
              if(deficit_lot <= 0) return;
              TRADE_COMMAND buy_command;
              buy_command._magic = intMagic;
              buy_command._lots = deficit_lot * hedge_avg_factor;// (1 + (0.5 * dist_multp));
              buy_command._lots = NormalizeDouble(buy_command._lots,2);
              buy_command._hedge_internal_trade = true;
              EnterBuy(buy_command);
              
        }
        if(sell_predicted_price > buy_avg_price && sell_predicted_price != 0)// && buy_avg_price + 10 * pips(strSymbol) < ask)
        {
              double deficit_lot = total_buy_lot - total_sell_lot;
              if(deficit_lot <= 0) return;
              TRADE_COMMAND sell_command;
              sell_command._magic = intMagic;
              sell_command._lots = deficit_lot * hedge_avg_factor;// (1 + (0.5 * dist_multp));
              sell_command._lots = NormalizeDouble(sell_command._lots,2);
              sell_command._hedge_internal_trade = true;
              EnterSell(sell_command);
        }
   }
}

void clsHedge::HedgeInternalSolve()
{
    if(!blHedgeTag) return;
    double buy_min_price  = dblMinPrice(1,intMagic);
    double sell_min_price = dblMinPrice(2,intMagic);
    double buy_max_price  = dblMaxPrice(1,intMagic);
    double sell_max_price = dblMaxPrice(2,intMagic);
    double max_price      = MathMax(buy_max_price,sell_max_price);
    double min_price      = MathMin(buy_min_price,sell_min_price);
    double gap            = max_price - min_price;
    double gap_pip        = (max_price - min_price)/pips(strSymbol);
    double mid            = max_price - (max_price - min_price)/2;
    double upper_third    = max_price - (max_price - min_price)*1/3;
    double lower_third    = max_price - (max_price - min_price)*2/3; 
    
   double buy_lot        = NormalizeDouble(dblTotalBuyLot(),2);
   double sell_lot       = NormalizeDouble(dblTotalSellLot(),2);
   
   string tag = (string)buy_max_price + (string)sell_min_price;// + (string)buy_lot + (string)sell_lot;
   
   double total_sell_lot = dblTotalSellLot();
   double total_buy_lot  = dblTotalBuyLot();
   double diff_lot = 0;
   
   double buy_entry_up_range = 0;
   double buy_entry_dn_range = 0;
   double sell_entry_up_range = 0;
   double sell_entry_dn_range = 0;
   if(gap_pip > 30)
   {
      buy_entry_up_range = (buy_max_price - (gap*2/3)) + 5 * pips(strSymbol);
      buy_entry_dn_range = (buy_max_price - (gap*2/3)) - 5 * pips(strSymbol);
      sell_entry_up_range = (buy_max_price - (gap*1/3)) + 5 * pips(strSymbol);
      sell_entry_dn_range = (buy_max_price - (gap*1/3)) - 5 * pips(strSymbol);
   }
   else
   {
      return;
      buy_entry_up_range = mid + 2 * pips(strSymbol);
      buy_entry_dn_range = mid - 2 * pips(strSymbol);
      sell_entry_up_range = mid + 2 * pips(strSymbol);
      sell_entry_dn_range = mid - 2 * pips(strSymbol);
   }
   double entry_up_range = (buy_max_price - (gap)/2) + 5 * pips(strSymbol);
   double entry_dn_range = (buy_max_price - (gap)/2) - 5 * pips(strSymbol);
   
   double ask = MarketInfo(strSymbol,MODE_ASK);
   double bid = MarketInfo(strSymbol,MODE_BID);
   
   if(intHedgeInitiator == 1 && blLRHedge())// intDailyDirection() == 1)
   {
        diff_lot = total_sell_lot - total_buy_lot;
        if(diff_lot > 0)
        {
              //price break down trigger assist trade and come back
              if(!blHedgeInternalTradeExist(1,intMagic))
              {
                   if(ask < buy_entry_up_range && ask > buy_entry_dn_range)
                   {
                          TRADE_COMMAND buy_command;
                          buy_command._magic = intMagic;
                          buy_command._trade_entry_tag = tag;
                          double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
                          double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
                          buy_command._lots = new_lot;
                          //buy_command._lots = diff_lot * hedge_internal_power;// (1 + (0.5 * dist_multp));
                          buy_command._lots = NormalizeDouble(buy_command._lots,2);
                          buy_command._hedge_internal_trade = true;
                          EnterBuy(buy_command);
                          blHedgeInternalTag = true;
                          intHedgeInternalCount++;
                          //Print("Lower third is ",lower_third);
                          //Print("Upper third is ",upper_third);
                          //ExpertRemove();
                   }
              }
        }
        if(blHedgeBreakEvenTag)
        {
             if(!blHedgeInternalTradeExist(2,intMagic))
             {
                  if(ask < sell_entry_up_range && ask > sell_entry_dn_range)
                  {
                          //Print("HERE PRE SELL");
                          //ExpertRemove();
                          TRADE_COMMAND sell_command;
                          sell_command._magic = intMagic;
                          sell_command._trade_entry_tag = tag;
                          double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
                          double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
                          sell_command._lots = new_lot;
                          //sell_command._lots = diff_lot * 3;
                          //sell_command._lots = MathAbs(diff_lot) * hedge_internal_power;// (1 + (0.5 * dist_multp));
                          sell_command._lots = NormalizeDouble(sell_command._lots,2);
                          sell_command._hedge_internal_trade = true;
                          EnterSell(sell_command);
                          blHedgeInternalTag = true;
                          intHedgeInternalCount++;
                  }
             }
        }
   } 
   /*
   if(TimeCurrent() >= D'2021.04.15 05:52')
   {
       Print("Preparing internal gap");
       Print("Gap is ",gap);
       Print("Entry up range is ",entry_up_range);
       Print("Entry dn range is ",entry_dn_range);
       ExpertRemove();
   }
   */
   if(intHedgeInitiator == 2 && blLRHedge())// intDailyDirection() == 2)
   {
        diff_lot = total_buy_lot - total_sell_lot;
        if(diff_lot > 0)
        {
              //price break up trigger assist trade and come back
              if(!blHedgeInternalTradeExist(2,intMagic))
              {
                   if(ask < sell_entry_up_range && ask > sell_entry_dn_range)
                   {
                          TRADE_COMMAND sell_command;
                          sell_command._magic = intMagic;
                          sell_command._trade_entry_tag = tag;
                          //sell_command._lots = diff_lot * 3;
                          sell_command._lots = MathAbs(diff_lot) * hedge_internal_power;// (1 + (0.5 * dist_multp));
                          sell_command._lots = NormalizeDouble(sell_command._lots,2);
                          sell_command._hedge_internal_trade = true;
                          EnterSell(sell_command);
                          blHedgeInternalTag = true;
                   }
              }
        }
        if(blHedgeBreakEvenTag)
        {
             if(!blHedgeInternalTradeExist(1,intMagic))
             {
                   if(ask < buy_entry_up_range && ask > buy_entry_dn_range)
                   {
                          TRADE_COMMAND buy_command;
                          buy_command._magic = intMagic;
                          buy_command._trade_entry_tag = tag;
                          buy_command._lots = diff_lot * hedge_internal_power;// (1 + (0.5 * dist_multp));
                          buy_command._lots = NormalizeDouble(buy_command._lots,2);
                          buy_command._hedge_internal_trade = true;
                          EnterBuy(buy_command);
                          blHedgeInternalTag = true;
                   }
             }
        }
   } 
}

/*
void clsHedge::HedgeInternalSolve()
{
    if(!blHedgeTag) return;
    double buy_min_price  = dblMinPrice(1,intMagic);
    double sell_min_price = dblMinPrice(2,intMagic);
    double buy_max_price  = dblMaxPrice(1,intMagic);
    double sell_max_price = dblMaxPrice(2,intMagic);
    double max_price      = MathMax(buy_max_price,sell_max_price);
    double min_price      = MathMin(buy_min_price,sell_min_price);
    double gap            = max_price - min_price;
    double gap_pip        = (max_price - min_price)/pips(strSymbol);
    double mid            = max_price - (max_price - min_price)/2;
    double upper_third    = max_price - (max_price - min_price)*1/3;
    double lower_third    = max_price - (max_price - min_price)*2/3; 
    
   //double buy_max_price  = dblMaxPrice(1,intMagic);
   //double sell_min_price = dblMinPrice(2,intMagic);
   double buy_lot        = NormalizeDouble(dblTotalBuyLot(),2);
   double sell_lot       = NormalizeDouble(dblTotalSellLot(),2);
   
   string tag = (string)buy_max_price + (string)sell_min_price;// + (string)buy_lot + (string)sell_lot;
   //double gap = MathMax(buy_max_price,sell_min_price) - MathMin(sell_min_price,sell_min_price);
   
   double total_sell_lot = dblTotalSellLot();
   double total_buy_lot  = dblTotalBuyLot();
   double diff_lot = 0;
   
   double buy_entry_up_range = (buy_max_price - (gap*2/3)) + 5 * pips(strSymbol);
   double buy_entry_dn_range = (buy_max_price - (gap*2/3)) - 5 * pips(strSymbol);
   
   double sell_entry_up_range = (buy_max_price - (gap*1/3)) + 5 * pips(strSymbol);
   double sell_entry_dn_range = (buy_max_price - (gap*1/3)) - 5 * pips(strSymbol);
   
   double entry_up_range = (buy_max_price - (gap)/2) + 5 * pips(strSymbol);
   double entry_dn_range = (buy_max_price - (gap)/2) - 5 * pips(strSymbol);
   
   double ask = MarketInfo(strSymbol,MODE_ASK);
   double bid = MarketInfo(strSymbol,MODE_BID);
   
   //if(gap_pip <= hedge_internal_solve_gap) return;
   
   diff_lot = total_sell_lot - total_buy_lot;
   
   if(diff_lot > 0)
   {
             //meaning we should perform internal hedge
             if(!blHedgeInternalTradeExist(1,intMagic) && intHedgeInitiator == 2)
             {
                  if(blHedgeBreakEvenTag)
                  {
                      if(ask < sell_entry_up_range && ask > sell_entry_dn_range)
                      {
                             TRADE_COMMAND buy_command;
                             buy_command._magic = intMagic;
                             buy_command._trade_entry_tag = tag;
                             buy_command._lots = diff_lot * 3;// (1 + (0.5 * dist_multp));
                             buy_command._lots = NormalizeDouble(buy_command._lots,2);
                             buy_command._hedge_internal_trade = true;
                             EnterBuy(buy_command);
                             //ExpertRemove();
                      }
                  }
                  else
                  {
                      if(bid < buy_entry_up_range && bid > buy_entry_dn_range)
                      {
                             TRADE_COMMAND sell_command;
                             sell_command._magic = intMagic;
                             sell_command._trade_entry_tag = tag;
                             //sell_command._lots = diff_lot * 3;
                             sell_command._lots = MathAbs(diff_lot) * 3;// (1 + (0.5 * dist_multp));
                             sell_command._lots = NormalizeDouble(sell_command._lots,2);
                             sell_command._hedge_internal_trade = true;
                             EnterSell(sell_command);
                             //Print("Done internal sell");
                             //ExpertRemove();
                             //Print("b");
                             //ExpertRemove();
                      }
                  }
             }
    }
    if(diff_lot < 0)
        {
             
             if(!blHedgeInternalTradeExist(2,intMagic) && intHedgeInitiator == 1)
             {
                   if(blHedgeBreakEvenTag)
                   {
                      if(bid < buy_entry_up_range && bid > buy_entry_dn_range)
                      {
                             TRADE_COMMAND sell_command;
                             sell_command._magic = intMagic;
                             sell_command._trade_entry_tag = tag;
                             //sell_command._lots = diff_lot * 3;
                             sell_command._lots = MathAbs(diff_lot) * 3;// (1 + (0.5 * dist_multp));
                             sell_command._lots = NormalizeDouble(sell_command._lots,2);
                             sell_command._hedge_internal_trade = true;
                             EnterSell(sell_command);
                             //Print("Done internal sell");
                             //ExpertRemove();
                             //Print("b");
                             //ExpertRemove();
                      }
                  }
                  else
                  {
                      if(ask < sell_entry_up_range && ask > sell_entry_dn_range)
                      {
                             TRADE_COMMAND buy_command;
                             buy_command._magic = intMagic;
                             buy_command._trade_entry_tag = tag;
                             buy_command._lots = diff_lot * 3;// (1 + (0.5 * dist_multp));
                             buy_command._lots = NormalizeDouble(buy_command._lots,2);
                             buy_command._hedge_internal_trade = true;
                             EnterBuy(buy_command);
                             //ExpertRemove();
                      }
                  }
             }
        }
   
   
   /*
   if(intHedgeInitiator == 1)
   {
        
        diff_lot = total_sell_lot - total_buy_lot;
        if(diff_lot > 0)
        {
             //meaning we should perform internal hedge
             if(!blHedgeInternalTradeExist(1,intMagic))
             {
                  if(ask < entry_up_range && ask > entry_dn_range)
                   {
                          TRADE_COMMAND buy_command;
                          buy_command._magic = intMagic;
                          buy_command._trade_entry_tag = tag;
                          buy_command._lots = diff_lot * 1.5;// (1 + (0.5 * dist_multp));
                          buy_command._hedge_internal_trade = true;
                          EnterBuy(buy_command);
                          //Print("B");
                          //ExpertRemove();
                   }
             }
        }
   }
   
   if(intHedgeInitiator == 2)
   {
        diff_lot = total_buy_lot - total_sell_lot;
        if(diff_lot > 0)
        {
             //meaning we should perform internal hedge
             if(!blHedgeInternalTradeExist(2,intMagic))
             {
                   
                   //Print("a");
                   if(bid < entry_up_range && bid > entry_dn_range)
                   {
                          TRADE_COMMAND sell_command;
                          sell_command._magic = intMagic;
                          sell_command._trade_entry_tag = tag;
                          sell_command._lots = diff_lot * 1.5;// (1 + (0.5 * dist_multp));
                          sell_command._hedge_internal_trade = true;
                          EnterSell(sell_command);
                          //Print("b");
                           //ExpertRemove();
                   }
             }
        }
        
   }
   
}
*/
void clsHedge::HedgeStart(int type, int magic=0, bool additional_hedge = false)
{
    //if(blPostBreakevenUnHedge()) return;
    double hedge_factor = 2;
    magic = magic == 0 ? intMagic : magic;
    if(magic != 0) intMagic = magic;
    
    
    if(blHedgeTradeExist(type,magic) && additional_hedge == false) return;
    
    double ask = MarketInfo(strSymbol,MODE_ASK);
    double bid = MarketInfo(strSymbol,MODE_BID);
    double max_lot_sell_price = dblMaxLotPrice(magic,2);
    double max_lot_buy_price  = dblMaxLotPrice(magic,1);
    double buy_max_price  = dblMaxPrice(1,magic);
    double sell_max_price = dblMaxPrice(2,magic);
    double buy_min_price  = dblMinPrice(1,magic);
    double sell_min_price = dblMinPrice(2,magic);
    //double min_lot_sell_price = dblMinLotPrice(magic,2);
    //double min_lot_buy_price  = dblMaxLotPrice(magic,1);
    double max_price = MathMax(buy_max_price,sell_max_price);
    //double min_price = MathMin(buy_min_price,sell_min_price);
    double min_price = buy_min_price != 0 && sell_min_price != 0 ? MathMin(buy_min_price,sell_min_price) : MathMax(buy_min_price,sell_min_price);
    double buy_dist  = ask - max_lot_sell_price;
    double sell_dist = max_lot_buy_price - bid;
    
    if(!blHedgeTag) intHedgeCount = 0;
    
    if(type == 1)
    {
         //if(blHedgeTag ) return;
         double sum_sell_lot = dblTotalSellLot();
         double sum_buy_lot  = dblTotalBuyLot();
         double lot_diff     = sum_sell_lot - sum_buy_lot;
         string strBuyTag = (string)lot_diff;
         int dist_multp = (int) MathCeil(buy_dist / 30 * pips(strSymbol)); 
         dist_multp = dist_multp == 0 ? 1 : dist_multp;
         Print("Hello a");
         if(
             (!blDuplicateTradeTagExist(1,magic,strBuyTag) || additional_hedge) &&
             lot_diff > 0 
           )
         {
              if(blHedgeTag && ask < max_price) return;
              Print("Hello b");
              if(blHedgeTag && !blHedgePostReverseTag) return;
              //if(lot_diff < dblMaxBuyLot()) lot_diff = dblMaxBuyLot();
              Print("Hello c");
              TRADE_COMMAND buy_command;
              buy_command._magic = magic;
              buy_command._trade_entry_tag = strBuyTag;
              buy_command._recover_mother = true;
              double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
              double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
              buy_command._lots = new_lot;
              double ori_lot = lot_diff * hedge_factor;// (1 + (0.5 * dist_multp));
              //if(MathAbs(new_lot - lot_diff) < 0.03 || new_lot > lot_diff) return;// blStrongHedgeTag = true;
              //if(!blHedgeTag) buy_command._lots = MathMax(ori_lot,new_lot);
              if(MathAbs(new_lot - lot_diff) > 0.03 && new_lot > lot_diff)
              { 
                 buy_command._lots = NormalizeDouble(buy_command._lots,2);
                 buy_command._hedge_trade = true;
                 EnterBuy(buy_command);
                 blHedgeTag = true;
                 intHedgeInitiator = 1;
                 intHedgeStartCount++;
              }
           } 
           
           
    }
    if(type == 2)
    {
         //if(blHedgeTag ) return;
         double sum_sell_lot = dblTotalSellLot();
         double sum_buy_lot  = dblTotalBuyLot();
         double lot_diff     = sum_buy_lot - sum_sell_lot;
         string strSellTag   = (string)lot_diff;
         int dist_multp = (int) MathCeil(sell_dist / (30 * pips(strSymbol))); 
         dist_multp = dist_multp == 0 ? 1 : dist_multp;
         /*
         if(TimeCurrent() >= D'2021.06.14 04:40')
         {
           Print("Here");
           Print("Duplicate tag check is ",blDuplicateTradeTagExist(2,magic,strSellTag));
           Print("Lot Diff is ",
           ExpertRemove();
         }
         */
         
         if(
              (!blDuplicateTradeTagExist(2,magic,strSellTag) || additional_hedge) &&
              lot_diff > 0 
           )
         {
              if(blHedgeTag && bid > min_price) return;
              if(blHedgeTag && !blHedgePostReverseTag) return;
              //if(lot_diff < dblMaxSellLot()) lot_diff = dblMaxSellLot();
              TRADE_COMMAND sell_command;
              sell_command._magic = magic;
              sell_command._trade_entry_tag = strSellTag;
              sell_command._recover_mother = true;
              double ongoing_loss = REF_TRADE.dblTotalOngoingProfit(strSymbol,intMagic);
              double new_lot = MathAbs(ongoing_loss / 20 / REF_MM.dblPipValuePerLot(strSymbol));
              sell_command._lots = new_lot;
              double ori_lot = lot_diff * hedge_factor;// (1 + (0.5 * dist_multp));
              //if(MathAbs(new_lot - lot_diff) < 0.03 || new_lot > lot_diff) return;//blStrongHedgeTag = true;
              //if(!blHedgeTag) sell_command._lots = MathMax(ori_lot,new_lot);
              if(MathAbs(new_lot - lot_diff) > 0.03 && new_lot > lot_diff)
              {
                 sell_command._lots = NormalizeDouble(sell_command._lots,2);
                 sell_command._hedge_trade = true;
                 EnterSell(sell_command);
                 Print("B");
                 blHedgeTag = true;
                 intHedgeInitiator = 2;
                 intHedgeStartCount++;
              }
              /*
              if(TimeCurrent() >= D'2021.06.14 04:40') 
               {
                   Print("Prepare rehedge sell");
                   //ExpertRemove();
               }
              
              Print("Sell Lot is ",sell_command._lots);
              Print("Hedge lot ratio is ",hedge_lot_ratio);
              Print("Sell dist is ",sell_dist);
              Print("Dist Multp is ",dist_multp);
              int dist_multp2 = (int) MathCeil(sell_dist / (30 * pips(strSymbol)));
              Print("Dist Mtp 2 is ",dist_multp2);
              
              ExpertRemove();
              */
         }
    }
}

void clsHedge::EnterBuy(TRADE_COMMAND &signal, bool reverse=false)
{
    signal._action  = MODE_TOPEN;
    double ask = MarketInfo(strSymbol,MODE_ASK);
    signal._symbol  = strSymbol;
    signal._entry   = signal._entry == 0 ? ask : signal._entry;
    int digit = (int)MarketInfo(signal._symbol,MODE_DIGITS);
    signal._entry   = NormalizeDouble(signal._entry,digit);
    signal._sl      = 0;
    signal._order_type = signal._order_type < 0 ? 0 : signal._order_type;
    if(signal._lots == 0)
    {
        Print("Hedge Buy No Lots specified");
        return;
    }
    signal._saved_lot = signal._lots;
    signal._tp      = 0;
    REF_TRADE.EnterTrade(signal,true,true);
}

void clsHedge::EnterSell(TRADE_COMMAND &signal, bool reverse=false)
{
    signal._action  = MODE_TOPEN;
    double bid = MarketInfo(strSymbol,MODE_BID);
    signal._symbol  = strSymbol;
    signal._entry   = signal._entry == 0 ? bid : signal._entry;
    int digit = (int)MarketInfo(signal._symbol,MODE_DIGITS);
    signal._entry   = NormalizeDouble(signal._entry,digit);
    signal._sl      = 0;
    signal._order_type = signal._order_type < 0 ? 1 : signal._order_type;
    if(signal._lots == 0)
    {
        Print("Hedge Sell No Lots specified");
        return;
    }
    signal._saved_lot = signal._lots;
    signal._tp      = 0;
    REF_TRADE.EnterTrade(signal,true,true);
}