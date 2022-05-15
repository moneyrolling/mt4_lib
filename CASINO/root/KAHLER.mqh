#include  "MASTER_INDI.mqh"
//+------------------------------------------------------------------+
//|  KAHLER INDICATOR  from https://www.quanttrader.com/             |
//+------------------------------------------------------------------+
enum KVOL_MODE
{
     PERCENT_MODE,
     ABSOLUTE_MODE
};



class clsKahler : 
     public  clsMasterIndi
{
   public:
     
              clsKahler(string strInputSymbol, int intInputTF, bool ea_mode=false);
              ~clsKahler();
     void     Updater(datetime time,bool preloop=false, bool special_check=false);
     double   dblHighs[];
     double   dblLows[];
     double   dblOpens[];
     double   dblCloses[];
     
     //OUTPUT to be called by others
     double   dblKVOLValue;
     int      intKVOLRank;
     double   dblKVOLs[];
     double   dblFullKVOLs[];
     bool     blKExtremeBull;
     bool     blKExtremeBear;
     int      intKExtremeHighestMomIdx;
     double   dblHighestMom;
     int      intBestMA;
     double   dblBestMAWinRate;
     
  
   protected:
     void     Oninit();
     void     StoreOHLC(int bar);
     
     //SELF ADAPT MA
     double   dblMAWinningPercent(int ma_period);
     void     GetAdaptMA();
     double   dblMATestValue;
     
     
   
   private:
     string     strIdentifier;
     bool       blEAMode;
     
     //FUNCTION
     //KVOL
     void       GetVol();
     void       GetExtreme(bool special_check=false);
     
     //input parameter
     //KVOL
     KVOL_MODE  vol_mode;
     double     dblVolMultiplier;   //multi: just a multiplier, like you can display 1 or 2 standard deviations..
     int        intVolDataPoints;   //datapoints: The number of bars used to calculate KVOL
     int        intVolReturnPeriod; //returnperiod: calculate the volatility for 1,2,3… bars
     int        intVolRankPeriod;   //to rank the KVOL over x period of time
     
     //EXTREME
     int        intExtremeMaxBar;
     int        intExtremeMinBar;
     double     dblExtremeExcessThreshold;
     
     //SELF ADAPT MA
     int        intAdaptMAMinPeriod;
     int        intAdaptMAMaxPeriod;
};



clsKahler::clsKahler(string strInputSymbol, int intInputTF, bool ea_mode=false):
        clsMasterIndi(strInputSymbol,intInputTF)
{
  Print("Kahler Constructor at Child ",strInputSymbol);
  blEAMode = ea_mode;
  this.Oninit();
}

clsKahler::~clsKahler(void)
{
  
}

void clsKahler::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"KAHLER"+(string)this.intPeriod;
    intMaxStore = 200; 
    //KVOL
    dblVolMultiplier = 1;
    intVolDataPoints = 30;
    intVolReturnPeriod = 5;
    intVolRankPeriod = 100;
    vol_mode = PERCENT_MODE;
    //EXTREME
    intExtremeMaxBar = 200;
    intExtremeMinBar = 5;
    dblExtremeExcessThreshold = 3;
    //AUTO ADAPT MA
    intAdaptMAMinPeriod = 3;
    intAdaptMAMaxPeriod = 50;
    if(blEAMode) Preloop();
}

void clsKahler::Updater(datetime time,bool preloop=false, bool special_check=false)
{
    int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
    StoreOHLC(latest_bar);
    GetVol();
    GetExtreme(special_check);
    if(latest_bar <= 10)GetAdaptMA();
}

void clsKahler::StoreOHLC(int bar)
{
    for(int i = bar + intMaxStore - 1; i >= bar ; i--)
    {
         double open  = iOpen(strSymbol,intPeriod,i);
         double high  = iHigh(strSymbol,intPeriod,i);
         double low   = iLow(strSymbol,intPeriod,i);
         double close = iClose(strSymbol,intPeriod,i);
         
         StoreArray(open, dblOpens,intMaxStore,true);
         StoreArray(high, dblHighs,intMaxStore,true);
         StoreArray(low,  dblLows,intMaxStore,true);
         StoreArray(close,dblCloses,intMaxStore,true);
    }
}

void clsKahler::GetVol()
{
    if(ArraySize(dblCloses) < intVolDataPoints + intVolReturnPeriod) return;
    
    double rpsum = 0;
    double rcsum = 0;
    
    for(int i = 0; i < intVolDataPoints - 1; i++)
    {
         double rc= MathMax((dblCloses[i]-dblCloses[i+intVolReturnPeriod])/dblCloses[i+intVolReturnPeriod],0); // % return of call
         double rp= MathMax((dblCloses[i+intVolReturnPeriod]-dblCloses[i])/dblCloses[i+intVolReturnPeriod],0); // % return of put
         rcsum=rcsum+rc; // sum of all %returns over time
         rpsum=rpsum+rp;
    }
    
    double icall = rcsum/intVolDataPoints;
    double iput  = rpsum/intVolDataPoints;
    double Kvol  = icall+iput;
    
    if(vol_mode == PERCENT_MODE)  dblKVOLValue = Kvol * 100;
    if(vol_mode == ABSOLUTE_MODE) dblKVOLValue = Kvol * dblCloses[0];
    
    StoreArray(dblKVOLValue,dblKVOLs,intVolRankPeriod);
    
    StoreArray(dblKVOLValue,dblFullKVOLs,intMaxStore);
    
    //process post rank
    if(ArraySize(dblKVOLs) >= intVolRankPeriod)
    {
        double hh   = dblKVOLs[ArrayMaximum(dblKVOLs)];
        double ll   = dblKVOLs[ArrayMinimum(dblKVOLs)];
        intKVOLRank = (int)(100-100*(hh-dblKVOLValue)/(hh-ll));
    }
}

void clsKahler::GetExtreme(bool special_check=false)
{
     blKExtremeBull = false;
     blKExtremeBear = false;
     if(ArraySize(dblFullKVOLs) < intExtremeMaxBar) return;
     double moms[];
     ArrayResize(moms,intExtremeMaxBar+1);
     for(int i = intExtremeMaxBar- 1; i >= intExtremeMinBar; i--)
     {
           double kvp = dblFullKVOLs[0] * sqrt(i);
           double   m = (dblCloses[0] - dblCloses[i]) / dblCloses[0];
           moms[i] = (MathAbs(m)/kvp) * 1000;
           //StoreArray( (MathAbs(m)/kvp) * 1000,moms,(intExtremeMaxBar - intExtremeMinBar) );
     }
	
     int highest_mom_idx = ArrayMaximum(moms);
     double highest_mom  = moms[highest_mom_idx];
     
     intKExtremeHighestMomIdx = highest_mom_idx;// + intExtremeMinBar;
     dblHighestMom = highest_mom;
     
     if(special_check)
     {
         Print("Hello");
         Print(" Highest Mom Idx is ",highest_mom_idx);
         Print(" Highest Mom Value is ",dblHighestMom);
     }
     
     if(highest_mom > dblExtremeExcessThreshold)
     {
          if(
               dblCloses[highest_mom_idx] > dblCloses[1] &&
               dblCloses[1] == dblCloses[ArrayMinimum(dblCloses,intKExtremeHighestMomIdx+1,1)] &&
               dblCloses[highest_mom_idx] ==  dblCloses[ArrayMaximum(dblCloses,intKExtremeHighestMomIdx+1,1)] 
            )
          {
              blKExtremeBull = true;
          }
          
          if(
               dblCloses[highest_mom_idx] <= dblCloses[1] &&
               dblCloses[1] == dblCloses[ArrayMaximum(dblCloses,intKExtremeHighestMomIdx+1,1)]  &&
               dblCloses[highest_mom_idx] ==  dblCloses[ArrayMinimum(dblCloses,intKExtremeHighestMomIdx+1,1)] 
            )
          {
              
              
              blKExtremeBear = true;
          }
     }     
}



double clsKahler::dblMAWinningPercent(int ma_period)
{
    //use 2 to wait for confirmation instead
    int lookback = 3; // prev bar to compare MA rising/falling and 
    int total_buy_predict = 0;
    int buy_predict_win = 0;
    
    int total_sell_predict = 0;
    int sell_predict_win = 0;
    
    //check buy predict
    for(int i = 2; i < intMaxStore - lookback; i++)
    {
         int cur_bar    = i;
         int prev_bar   = i+lookback;
         int counter_chk_bar = cur_bar + 1;
         double ma_cur  = dblMAOnArray(dblCloses,ma_period,cur_bar,ARRAY_EMA);
         double ma_prev = dblMAOnArray(dblCloses,ma_period,prev_bar,ARRAY_EMA);
         if(ma_cur > ma_prev) //MA picking up
         {
             //if(dblCloses[cur_bar] > ma_cur) // make sure the price is above MA
             //{
                  if(dblCloses[counter_chk_bar] > dblCloses[cur_bar]) // we look forward to see whether correct or not the price rise
                  {
                      buy_predict_win++;
                  }
                  total_buy_predict++;
             //}
         }
    }
    
    //check sell predict
    for(int i = 2; i < intMaxStore - lookback; i++)
    {
         int cur_bar    = i;
         int prev_bar   = i+lookback;
         int counter_chk_bar = cur_bar + 1;
         double ma_cur  = dblMAOnArray(dblCloses,ma_period,cur_bar,ARRAY_EMA);
         double ma_prev = dblMAOnArray(dblCloses,ma_period,prev_bar,ARRAY_EMA);
         if(ma_cur < ma_prev) //MA picking dn
         {
             //if(dblCloses[cur_bar] < ma_cur) // make sure the price is above MA
             //{
                  if(dblCloses[counter_chk_bar] < dblCloses[cur_bar]) // we look forward to see whether correct or not the price rise
                  {
                      sell_predict_win++;
                  }
                  total_sell_predict++;
             //}
         }
    }
    
    int total_win_predict = buy_predict_win + sell_predict_win;
    int total_predict     = total_buy_predict + total_sell_predict;
    
    
    double win_rate = total_predict != 0 ? (double)total_win_predict/(double)total_predict : 0;
    return(win_rate);
}

void clsKahler::GetAdaptMA()
{
     intBestMA = 0;
     dblBestMAWinRate = 0;
     if(ArraySize(dblCloses) < intAdaptMAMinPeriod + intAdaptMAMaxPeriod) return;
     double ma_cordae[];
     ArrayResize(ma_cordae,intAdaptMAMaxPeriod+1);
     dblMATestValue = dblMAWinningPercent(50);
     for(int i = intAdaptMAMinPeriod; i <= intAdaptMAMaxPeriod; i++)
     {
          ma_cordae[i] = dblMAWinningPercent(i);
     } 
     int best_ma_idx = ArrayMaximum(ma_cordae);
     intBestMA = best_ma_idx;
     dblBestMAWinRate = ma_cordae[intBestMA];
}