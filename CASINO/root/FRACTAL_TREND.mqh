#include  "MASTER_INDI.mqh"
#include  "MASTER_CONFIG.mqh"
enum FIBO_TRADE_INPUT
{
   FIBO000,  
   FIBO236,
   FIBO382,
   FIBO500,
   FIBO618,
   FIBO702,
   FIBO786,
   FIBO100
};

//double FIBO_RATIO[3][2] = { 0.681,0.782,   0.84,1.0,   1.13,1.23};
double FIBO_RATIO[4][2] = { 0.238, 0.382, 0.618,0.693,  0.884,1.0,   1.13,1.23}; //{0.238, 0.382}; //
double TREND_FOLLOW_FIBO_RATIO[3][2] = { 0.236,0.382,  0.441,0.5, 0.693,0.782};

class clsFracTrend : 
     public  clsMasterIndi
{
   public:
     
              clsFracTrend(string strInputSymbol, int intInputTF);
              ~clsFracTrend();
     void     Updater(datetime time,bool preloop=false);
     double   dblFractalPeak[];
     double   dblFractalCrest[];
     int      intBuyLowIdx;
     int      intBuyHighIdx;
     int      intSellLowIdx;
     int      intSellHighIdx;
     int      intCurTrend;
     int      intTrendList[];
     double   dblBuyBreakoutPrice;
     double   dblSellBreakoutPrice;
     double   dblBuyTrendTag;
     int      intBuyTrendFiboTag;
     double   dblBuyUpRange;
     double   dblBuyDnRange;
     double   dblBuyDnBreakPrice;
     double   dblSellTrendTag;
     int      intSellTrendFiboTag;
     double   dblSellUpRange;
     double   dblSellDnRange;
     double   dblSellUpBreakPrice;
     
   protected:
     void    Oninit();
     void    FindFractal();
     void    LoopCustomOHLC(int bar);
     void    FindBuyZone();
     void    FindSellZone();
     void    CheckTrend();
   
   private:
     string  strIdentifier;
     int     intBreakout;
};

clsFracTrend::clsFracTrend(string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
{
  Print("Constructor at Child ",strInputSymbol);
  //this.CALL_FROM_FIBO = fibo_call;
  this.Oninit();
}

clsFracTrend::~clsFracTrend(void){}

void clsFracTrend::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"FRT"+(string)this.intPeriod;
    intMaxStore = 400; 
    intBreakout = 10;
}

void clsFracTrend::Updater(datetime time,bool preloop=false)
{
   //Alert("Creating Label at ",this.intPeriod);
   int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
   //Print("Looping at bar of ",latest_bar);
   LoopCustomOHLC(latest_bar);
   FindFractal();
   FindBuyZone();
   FindSellZone();
   CheckTrend();
   StoreArray(intCurTrend,intTrendList);
}
     

void clsFracTrend::LoopCustomOHLC(int bar)
{
    ArrayFree(Opens);
    ArrayResize(Opens,intMaxStore);
    ArrayFree(Highs);
    ArrayResize(Highs,intMaxStore);
    ArrayFree(Lows);
    ArrayResize(Lows,intMaxStore);
    ArrayFree(Closes);
    ArrayResize(Closes,intMaxStore);
    ArrayFree(Times);
    ArrayResize(Times,intMaxStore);
    ArrayFree(dblFractalPeak);
    ArrayResize(dblFractalPeak,intMaxStore);
    ArrayFree(dblFractalCrest);
    ArrayResize(dblFractalCrest,intMaxStore);
    int count = intMaxStore - 1;
    for(int i = bar + intMaxStore - 1; i >= bar; i--)
    {
         //Alert("Looping i of ",i);
         Opens[count]   = iOpen(strSymbol,intPeriod,i);
         Highs[count]   = iHigh(strSymbol,intPeriod,i);
         Lows[count]    = iLow (strSymbol,intPeriod,i);
         Closes[count]  = iClose(strSymbol,intPeriod,i);
         Times[count]   = iTime(strSymbol,intPeriod,i);
         double frac_up = iFractals(strSymbol,intPeriod,MODE_UPPER,i);
         double frac_dn = iFractals(strSymbol,intPeriod,MODE_LOWER,i);
         dblFractalPeak[count]  = frac_up == Highs[count] ? Highs[count] : 0;
         dblFractalCrest[count] = frac_dn == Lows[count]  ? Lows[count]  : 0;
         count--;
    }
}

void clsFracTrend::FindFractal()
{
     
     
     //refine to find a better peak and crest
     for(int i = 0; i < intMaxStore; i++)
     {
          if(dblFractalPeak[i] != 0)
          {
               for(int j = i + 1; j < intMaxStore; j++)
               {
                    if(dblFractalCrest[j] != 0)
                    {
                         i = j;
                         break;
                    }
                    if(dblFractalPeak[j] != 0)
                    {
                        if(dblFractalPeak[j] > dblFractalPeak[i]) dblFractalPeak[i] = 0;
                        if(dblFractalPeak[j] < dblFractalPeak[i]) dblFractalPeak[j] = 0;
                        continue;
                    }
               }
          }
     }
     
     for(int i = 0; i < intMaxStore; i++)
     {
          if(dblFractalCrest[i] != 0)
          {
               for(int j = i + 1; j < intMaxStore; j++)
               {
                    if(dblFractalPeak[j] != 0)
                    {
                         i = j;
                         break;
                    }
                    if(dblFractalCrest[j] != 0)
                    {
                        if(dblFractalCrest[j] > dblFractalCrest[i]) dblFractalCrest[j] = 0;
                        if(dblFractalCrest[j] < dblFractalCrest[i]) dblFractalCrest[i] = 0;
                        continue;
                    }
               }
          }
     }
     
}

void clsFracTrend::FindBuyZone()
{
     intBuyHighIdx  = 888;
     intBuyLowIdx   = 888;
     dblBuyUpRange  = 888;
     dblBuyDnRange  = 888;
     dblBuyDnBreakPrice = 888;
     intBuyTrendFiboTag = 888;
     
     for(int i = 0; i < intMaxStore; i++)
     {
         if(dblFractalCrest[i] != 0 && Lows[0] > dblFractalCrest[i])
         {
             bool valid = false;
             for(int j = i-1; j>= 0; j--)
             {
                  if(dblFractalPeak[j] != 0)
                  {
                       valid = true;
                       //intBuyHighIdx = j;
                       intBuyHighIdx = intHighestIdx(Highs,i,0);
                       break;
                  }
             }
             if(valid)
             {
                 intBuyLowIdx = i;
                 break;
             }
         }
     }
     if(intBuyHighIdx != 888 && intBuyLowIdx != 888)
     {
        double high  = Highs[intBuyHighIdx];
        double low   = Lows[intBuyLowIdx];
        double range = high - low;
        if(range < 20 * pips(strSymbol)) return;
        int fibo_size = ArraySize(FIBO_RATIO)/2;
        for(int i = 0; i < fibo_size; i++)
        {
              double up_range = high - (range * FIBO_RATIO[i][0]);
              double dn_range = high - (range * FIBO_RATIO[i][1]);
              
              if(//MarketInfo(strSymbol,MODE_ASK) <= up_range &&
                 //MarketInfo(strSymbol,MODE_ASK) >= dn_range 
                   Lows[0] <= up_range &&
                   Lows[0] >= dn_range
                )
              {
                    dblBuyUpRange = up_range;
                    dblBuyDnRange = dn_range;
                    intBuyTrendFiboTag = i;
                    break;
              }
        }
        dblBuyDnBreakPrice = high -  (range * FIBO_RATIO[fibo_size-1][1])  - intBreakout * pips(strSymbol);
        dblSellTrendTag    = Lows[intBuyLowIdx];
     }
}

void clsFracTrend::FindSellZone()
{
     intSellLowIdx  = 888;
     intSellHighIdx = 888;
     dblSellUpRange = 888;
     dblSellDnRange = 888;
     dblSellUpBreakPrice = 888;
     intSellTrendFiboTag  = 888;
     for(int i = 0; i < intMaxStore; i++)
     {
         if(dblFractalPeak[i] != 0 && Highs[0] < dblFractalPeak[i])
         {
             bool valid = false;
             for(int j = i-1; j>= 0; j--)
             {
                  if(dblFractalCrest[j] != 0)
                  {
                       valid = true;
                       //intSellLowIdx = j;
                       intSellLowIdx = intLowestIdx(Lows,i,0);
                       break;
                  }
             }
             if(valid)
             {
                 intSellHighIdx = i;
                 break;
             }
         }
     }
     if(intSellHighIdx != 888 && intSellLowIdx != 888)
     {
        double high  = Highs[intSellHighIdx];
        double low   = Lows[intSellLowIdx];
        double range = high - low;
        if(range < 20 * pips(strSymbol)) return;
        int fibo_size = ArraySize(FIBO_RATIO)/2;
        for(int i = 0; i < fibo_size; i++)
        {
              double up_range = low  + (range * FIBO_RATIO[i][1]);
              double dn_range = low  + (range * FIBO_RATIO[i][0]);
              
              if(//MarketInfo(strSymbol,MODE_BID) <= up_range &&
                 //MarketInfo(strSymbol,MODE_BID) >= dn_range 
                 Highs[0] <= up_range &&
                 Highs[0] >= dn_range
                )
              {
                    dblSellUpRange = up_range;
                    dblSellDnRange = dn_range;
                    intSellTrendFiboTag = i;
                    break;
              }
        }
        dblSellUpBreakPrice = low +  (range * FIBO_RATIO[fibo_size-1][1]) + intBreakout * pips(strSymbol);
        dblBuyTrendTag      = Highs[intSellHighIdx];
        
    } 
}

void clsFracTrend::CheckTrend()
{
    //RESET ON EACH NEW RUN
    intCurTrend = 0;
    dblBuyBreakoutPrice  = 0;
    dblSellBreakoutPrice = 0;
    if(intBuyHighIdx == 888 || intSellHighIdx == 888) return;
    if(intBuyHighIdx == intSellHighIdx ||
       intBuyLowIdx  == intSellLowIdx
      )
    {
           intCurTrend = 3; //pending for breakout
           dblBuyBreakoutPrice  = MathMax(Highs[intBuyHighIdx],Highs[intSellHighIdx]);
           dblSellBreakoutPrice = MathMin(Lows[intBuyLowIdx],Lows[intSellLowIdx]);  
    }
    
    else
    {
          if(intBuyHighIdx == 0 && intSellHighIdx != 0)
          {
              intCurTrend = 1;
          }
          else if(intSellLowIdx == 0 && intBuyLowIdx != 0)
          {
              intCurTrend = 2;
          }
    }
    
    
    
}

