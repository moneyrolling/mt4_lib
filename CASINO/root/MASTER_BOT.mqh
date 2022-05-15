#include "/MONEY_MANAGEMENT.mqh"
clsMoneyManagement *MM;
clsTradeClass      *TRADE;
clsTradeClass      *PSEUDO_TRADE;
clsMoneyManagement *PSEUDO_MM;

enum ENUM_TIME {
    PM01 =0,
    PM05 =1,
    PM15 =2,
    PM30 =3,
    PH01 =4,
    PH04 =5,
    PD01 =6,
    PW01 =7,
    PMN01=8
};

int IntPeriodList[9] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1,
                        PERIOD_H4, PERIOD_D1, PERIOD_W1,  PERIOD_MN1
                       };
class clsMasterBot 
{
     public:
         clsMasterBot(string strInputSymbol);
         ~clsMasterBot();
         void   Updater();
         void   ATRAutoTrailing(int mode, int atr_tf, int atr_period=14, int atr_multiplier=3);
         
         
     protected:
         void   Oninit();
         string strSymbols[];
         int    intBotMagic;
         string strSymbol;
         void   ATRCount(int atr_tf, int atr_period);
         bool   blNewBar(int intInputTF, bool use_first=true);
         double dblATR;
     private:
         
         int    intATRPosCount;
         
         
};

clsMasterBot::clsMasterBot(string strInputSymbol)
{
     //Print("Hello Running Master Constructor");
     this.strSymbol = strInputSymbol;
     this.Oninit();
}

clsMasterBot::~clsMasterBot(void)
{
     
}

void clsMasterBot::Oninit(void)
{
    this.intBotMagic = 0; 
    //Print("Hello Running Master Oninit");
}

void clsMasterBot::Updater(void)
{
   
}

bool clsMasterBot::blNewBar(int intInputTF, bool use_first=true)
{
    static int save_bar;
    static double save_close;
    datetime current_time = TimeCurrent();
    int      cur_bar = (int)(current_time/(intInputTF*60));
    
    //Print("Latest Time is ",TimeCurrent());
    //Print("Timeframe value is ",this.intPeriod);
    if(save_bar == 0)
    {
         if(use_first)
         {
              //Print("I save A");
              save_bar = cur_bar;
              save_close = iClose(this.strSymbol,intInputTF,1);
              //Print("A Latest Bar Close is ",save_close);
              return(true);
         }
    }
    else
    {
         if(save_bar != cur_bar)
         {
              //Print("I save B");
              save_bar = cur_bar;
              save_close = iClose(this.strSymbol,intInputTF,1);
              //Print("B Latest Bar Close is ",save_close);
              return(true);
         }
    }
    return(false);
}

void clsMasterBot::ATRCount(int atr_tf, int atr_period)
{
    if(this.blNewBar(atr_tf))
    {
        this.dblATR     = iATR(this.strSymbol,atr_tf,atr_period,1);  //WE ONLY USE CLOSED BAR
        double atr_prev = iATR(this.strSymbol,atr_tf,atr_period,2);
        
        double POC_ATR = (atr_prev/this.dblATR) - 1;
        
        if(POC_ATR > 0)
        {this.intATRPosCount+=1;}
        else
        {
           if(POC_ATR < 0)
           {this.intATRPosCount=0;}
        }
    }
}

void clsMasterBot::ATRAutoTrailing(int mode, int atr_tf, int atr_period=14, int atr_multiplier=3)
{
    //PRELOAD ATR
    this.ATRCount(atr_tf,atr_period);
    //MODE 1 : ATR TRAIL
    //MODE 2 : INVERSE ATR TRAIL
    double buy_latest_sl = 0;
    double sell_latest_sl = 0;     
    
    switch(mode)
    {
         case 1:
            //we do as user default input
            break;
         case 2:
            //INVERSE FORMULA : 
            //1. We find the ROC of ATR, we take 2 CONSECUTIVE ROC of ATR
            //2. If ROC ATR > 0, we count + 1, we revert to 0 once ROC ATR < 0
            //3. If ATR Pos Count > 6,   latest SL will just be 1 x ATR
            //   If ATR Pos Count 4 - 6, latest SL will just be 2 x ATR
            //   If ATR Pos Count 1 - 3, latest SL will just be 3 x ATR
            //   If ATR Pos Count < 1,   latest SL will just be 4 x ATR
                  if(this.intATRPosCount > 6)
                  {
                     atr_multiplier = 1;
                  }
                  else if(this.intATRPosCount >= 4 && this.intATRPosCount <= 6)
                  {
                     atr_multiplier = 2;
                  }
                  else if(this.intATRPosCount >= 1 && this.intATRPosCount <= 3)
                  {
                     atr_multiplier = 3;
                  }
                  else if(this.intATRPosCount < 1)
                  {
                     atr_multiplier = 4;
                  }
            break;
    }
    buy_latest_sl  = MarketInfo(this.strSymbol,MODE_BID) - (atr_multiplier*this.dblATR);
    sell_latest_sl = MarketInfo(this.strSymbol,MODE_ASK) + (atr_multiplier*this.dblATR);
    
    TRADE_COMMAND BUY_TRAIL;
    BUY_TRAIL._action = MODE_TCHNG;
    BUY_TRAIL._trailing_input = buy_latest_sl; 
    BUY_TRAIL._trailing_mode  = 2;//we use predefined sl
    BUY_TRAIL._symbol         = this.strSymbol;
    BUY_TRAIL._order_type     = 0;
    TRADE.TrailTrade(BUY_TRAIL);
    
    TRADE_COMMAND SELL_TRAIL;
    SELL_TRAIL._action = MODE_TCHNG;
    SELL_TRAIL._trailing_input = sell_latest_sl; 
    SELL_TRAIL._trailing_mode  = 2;//we use predefined sl
    SELL_TRAIL._symbol         = this.strSymbol;
    SELL_TRAIL._order_type     = 1;
    TRADE.TrailTrade(SELL_TRAIL);
    
}








