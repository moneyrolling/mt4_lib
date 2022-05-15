#include  "MASTER_INDI.mqh"

class clsTradeEnhancer : 
     public  clsMasterIndi
{
      public:
            clsTradeEnhancer(string strInpSymbol, int intInpBasePeriod);
            ~clsTradeEnhancer();
            bool           blOverZone();
            bool           blNonHighVolatilityZone();
            bool           blNonSRZone(int type);
            bool           blNonCollapsedZone(int type);
            bool           blPriceBoom(int type);
            void           Updater();
      
      protected:
            void            Oninit();
            
            
      private:
            double          dblMA_8_1P_M1;
            double          dblMA_8_2P_M1;
            double          dblMA_8_3P_M1;
            double          dblMA_5_1P_M15;
            double          dblMA_5_2P_M15;
            double          dblMA_5_3P_M15;
            double          dblPrevBid;
            double          dblPrevAsk;
};

clsTradeEnhancer::clsTradeEnhancer(string strInpSymbol, int intInpBasePeriod):
        clsMasterIndi(strInpSymbol,intInpBasePeriod)
{
     strSymbol = strInpSymbol;
     intPeriod = intInpBasePeriod;
}

clsTradeEnhancer::~clsTradeEnhancer(void){}

void clsTradeEnhancer::Updater()
{
     if(blNewBar())
     {
         dblMA_8_1P_M1  = iMA(strSymbol,intPeriod,8,0,MODE_EMA,PRICE_CLOSE,1);
         dblMA_8_2P_M1  = iMA(strSymbol,intPeriod,8,0,MODE_EMA,PRICE_CLOSE,2);
         dblMA_8_3P_M1  = iMA(strSymbol,intPeriod,8,0,MODE_EMA,PRICE_CLOSE,3);
         dblMA_5_1P_M15 = iMA(strSymbol,PERIOD_M15,5,0,MODE_EMA,PRICE_CLOSE,1);
         dblMA_5_2P_M15 = iMA(strSymbol,PERIOD_M15,5,0,MODE_EMA,PRICE_CLOSE,2);
         dblMA_5_3P_M15 = iMA(strSymbol,PERIOD_M15,5,0,MODE_EMA,PRICE_CLOSE,3);
     }
     double bid = MarketInfo(strSymbol,MODE_BID);
     if(bid != dblPrevBid) dblPrevBid = bid;
     //Print("Current BId is ",bid);
     //Print("Previous bid is ",dblPrevBid);
}

bool clsTradeEnhancer::blOverZone()
{
    double low_1  = iLow(strSymbol,intPeriod,1);
    double high_1 = iHigh(strSymbol,intPeriod,1);
    double low_2  = iLow(strSymbol,intPeriod,2);
    double high_2 = iHigh(strSymbol,intPeriod,2);
    double low_3  = iLow(strSymbol,intPeriod,3);
    double high_3 = iHigh(strSymbol,intPeriod,3);
    double low_1_m15  = iLow(strSymbol,PERIOD_M15,1);
    double high_1_m15 = iHigh(strSymbol,PERIOD_M15,1);
    //Print("Low 1 is ",low_1);
    //Print("MA 8 is ",dblMA_8_1P_M1);
    if
    (  //start of the wave
       (dblMA_8_1P_M1 > low_1 && dblMA_8_1P_M1 < high_1) ||
       (dblMA_8_2P_M1 > low_2 && dblMA_8_2P_M1 < high_2) ||
       (dblMA_8_3P_M1 > low_3 && dblMA_8_3P_M1 < high_3)
    )
    {
         //Print("Enter Here");
         //Print("MA 15 is ",dblMA_5_1P_M15);
         //Print("High 15 is ",high_1_m15);
         if(dblMA_5_1P_M15 > low_1_m15 && dblMA_5_1P_M15 < high_1_m15)  //start of the wave - on the previous bar of the higher timeframe (М15)
         {
            return(true);
         }
    }
    return(false);
}

bool clsTradeEnhancer::blNonHighVolatilityZone()
{
    double low_1  = iLow(strSymbol,intPeriod,1);
    double high_1 = iHigh(strSymbol,intPeriod,1);
    double low_2  = iLow(strSymbol,intPeriod,2);
    double high_2 = iHigh(strSymbol,intPeriod,2);
    double low_3  = iLow(strSymbol,intPeriod,3);
    double high_3 = iHigh(strSymbol,intPeriod,3);
    double low_1_m15  = iLow(strSymbol,PERIOD_M15,1);
    double high_1_m15 = iHigh(strSymbol,PERIOD_M15,1);
    double low_2_m15  = iLow(strSymbol,PERIOD_M15,2);
    double high_2_m15 = iHigh(strSymbol,PERIOD_M15,2);
    double low_3_m15  = iLow(strSymbol,PERIOD_M15,3);
    double high_3_m15 = iHigh(strSymbol,PERIOD_M15,3);
    
    if(
          high_1 - low_1 <= 20 * pips(strSymbol) &&
          high_2 - low_2 <= 20 * pips(strSymbol) &&
          high_3 - low_3 <= 20 * pips(strSymbol) &&
          high_1_m15 - low_1_m15 <= 30 * pips(strSymbol) &&
          high_2_m15 - low_2_m15 <= 30 * pips(strSymbol) &&
          high_3_m15 - low_3_m15 <= 30 * pips(strSymbol) &&
          (high_1 - low_1) >= (1.1 * (high_2 - low_2))   &&
          (high_1 - low_1)  < (3.0 * (high_2 - low_2))   
      )
    {
          return(true);
    }
    return(false);
}

bool clsTradeEnhancer::blNonSRZone(int type)
{
    double low_1  = iLow(strSymbol,intPeriod,1);
    double high_1 = iHigh(strSymbol,intPeriod,1);
    double low_1_m15  = iLow(strSymbol,PERIOD_M15,1);
    double high_1_m15 = iHigh(strSymbol,PERIOD_M15,1);
    if(type == 1)
    {
        if(
              MarketInfo(strSymbol,MODE_BID) > high_1 &&
              MarketInfo(strSymbol,MODE_BID) > high_1_m15
          )
          {
              return(true);
          }
    }
    if(type == 2)
    {
        if(
              MarketInfo(strSymbol,MODE_BID) < low_1 &&
              MarketInfo(strSymbol,MODE_BID) < low_1_m15
          )
          {
              return(true);
          }
    }
    return(false);
}

bool clsTradeEnhancer::blPriceBoom(int type)
{
     double   bid       = MarketInfo(strSymbol,MODE_BID);
     double   point     = MarketInfo(strSymbol,MODE_POINT);
     if(type == 1)
     {
         if(dblPrevBid != 0 && bid - dblPrevBid > 10000 * point)
         {
             return(true);
         }
     }
     if(type == 2)
     {
         if(dblPrevBid != 0 && dblPrevBid - bid > 10000 * point)
         {
             return(true);
         }
     }
     return(false);
}

bool clsTradeEnhancer::blNonCollapsedZone(int type)
{
     //REDUCE RISLS RELATED TO PRICE COLLAPSES AT THE TIME OF MARKET ENTRY----------------------
     double   bid       = MarketInfo(strSymbol,MODE_BID);
     double   point     = MarketInfo(strSymbol,MODE_POINT);
     double   open_0    = iOpen(strSymbol,PERIOD_M1,0);
     double   high_0    = iHigh(strSymbol,PERIOD_M1,0);
     double   low_0     = iLow(strSymbol,PERIOD_M1,0);
     datetime time_0    = iTime(strSymbol,PERIOD_M1,0);
     double   open_1    = iOpen(strSymbol,PERIOD_M1,1);
     double   close_1   = iClose(strSymbol,PERIOD_M1,1);
     double   O_cur_m15 = iOpen(strSymbol,PERIOD_M15,0);
     datetime Time_cur  = TimeCurrent();
     datetime Time_cur_m15 = iTime(strSymbol,PERIOD_M15,0);
     double   atr_6      = iATR(strSymbol,PERIOD_M1,6,0);
     double   atr_6_prev = iATR(strSymbol,PERIOD_M1,6,1);
     
     if(type == 1)
     {
        if(
            (
               ((atr_6 >= 2200*point) && (Time_cur - time_0) <= 20))
               //bid < open_0 && (high_0 - low_0) >= 100*point && (Time_cur - time_0) <= 20)           //exit conditions (in any zones) during a price collapse (reference point - М1 current candle open price)
               //||
            //(bid < O_cur_m15 && (O_cur_m15 - bid) >= 200*point && (Time_cur - Time_cur_m15) <= 120) //exit conditions (in any area) during the price collapse (reference point - current М15 candle open price)
             /* ||
              ((Time_cur - OrderOpenTime()) > 60 && Close[1] < Open[1] && 
              (Open[1] - Close[1]) >= 200*Point)
              */ 
          )
        {
            return(false);
        }
     }
     if(type == 2)
     {
         if( 
              ((atr_6 >= 2200*point) && (Time_cur - time_0) <= 20) 
              //(bid > open_0 && (high_0 - low_0) >= 100*point && (Time_cur - time_0) <= 20)          //exit conditions (in any area) during a price collapse (reference point - current M1 candle Open price)
              //       ||
              //(bid > O_cur_m15 && (bid - O_cur_m15) >= 200*point && (Time_cur - Time_cur_m15) <= 120)
           )
         {
             return(false);
         }
     }
     return(true);
}

