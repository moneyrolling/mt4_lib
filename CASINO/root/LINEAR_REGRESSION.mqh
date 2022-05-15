#include  "MASTER_INDI.mqh"
#include  "MASTER_CONFIG.mqh"
extern int lr_lookback = 50;

class clsLinearRegression: 
     public  clsMasterIndi
{
     public:
                         clsLinearRegression(string strInputSymbol, int intInputTF);
                         ~clsLinearRegression();
         void            Updater(datetime time, bool preloop=false);
         double          dblOpen_m;
         double          dblHigh_m;
         double          dblLow_m;
         double          dblClose_m;
         double          dblOpen_c;
         double          dblHigh_c;
         double          dblLow_c;
         double          dblClose_c;
         double          dblHighs[];
         double          dblLows[];
         double          dblOpens[];
         double          dblCloses[];
         double          dblOpen_ms[];
         double          dblHigh_ms[];
         double          dblLow_ms[];
         double          dblClose_ms[];
         double          dblOpen_LR[];
         double          dblHigh_LR[];
         double          dblLow_LR[];
         double          dblClose_LR[];
         int             intHighTrend;
         int             intLowTrend;
         int             intOpenTrend;
         int             intCloseTrend;
     
     protected:
         void            Oninit();
         void            Collector(int start_bar);
         void            FindRegressor();
         void            FindTrend();
         
     private:
         string          strIdentifier;
         
         
};

clsLinearRegression::clsLinearRegression(string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
{
  Print("Constructor at Child ",strInputSymbol);
  //this.CALL_FROM_FIBO = fibo_call;
  this.Oninit();
}

clsLinearRegression::~clsLinearRegression(void){}

void clsLinearRegression::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"LR"+(string)this.intPeriod;
    intMaxStore = lr_lookback; 
}

void clsLinearRegression::Updater(datetime time,bool preloop=false)
{
   //Alert("Creating Label at ",this.intPeriod);
   int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
   //reset values 
   ArrayFree(dblOpens);
   ArrayFree(dblHighs);
   ArrayFree(dblLows);
   ArrayFree(dblCloses);
   ArrayFree(dblOpen_LR);
   ArrayFree(dblHigh_LR);
   ArrayFree(dblLow_LR);
   ArrayFree(dblClose_LR);
   
   dblOpen_m  = 0;
   dblOpen_c  = 0;
   dblHigh_m  = 0;
   dblHigh_c  = 0;
   dblLow_m   = 0;
   dblLow_c   = 0;
   dblClose_m = 0;
   dblClose_c = 0;
   
   intOpenTrend  = 0;
   intHighTrend  = 0;
   intLowTrend   = 0;
   intCloseTrend = 0;
   Collector(latest_bar);
   FindRegressor();
   FindTrend();
}

void clsLinearRegression::Collector(int start_bar)
{
   //Print("Start Bar is ",start_bar);
   for(int i = start_bar + intMaxStore - 1; i >= start_bar; i--)
   {
        double open  = iOpen(strSymbol,intPeriod,i);
        double high  = iHigh(strSymbol,intPeriod,i);
        double low   = iLow(strSymbol,intPeriod,i);
        double close = iClose(strSymbol,intPeriod,i);
        
        StoreArray(open,dblOpens,intMaxStore,true);
        StoreArray(high,dblHighs,intMaxStore,true);
        StoreArray(low,dblLows,intMaxStore,true);
        StoreArray(close,dblCloses,intMaxStore,true);
   }
}

void clsLinearRegression::FindRegressor(void)
{
    if(ArraySize(dblOpens) != intMaxStore) return;
    
    double open_sum_y  = 0;
    double open_sum_xy = 0;
    double open_sum_x  = 0;
    double open_sum_x2 = 0;
    double open_c      = 0;
    
    double high_sum_y  = 0;
    double high_sum_xy = 0;
    double high_sum_x  = 0;
    double high_sum_x2 = 0;
    double high_c      = 0;
    
    double low_sum_y  = 0;
    double low_sum_xy = 0;
    double low_sum_x  = 0;
    double low_sum_x2 = 0;
    double low_c      = 0;
    
    double close_sum_y  = 0;
    double close_sum_xy = 0;
    double close_sum_x  = 0;
    double close_sum_x2 = 0;
    double close_c      = 0;
    
    for(int i=0; i< intMaxStore; i++)
    {
      open_sum_y  += dblOpens[i];
      open_sum_xy += dblOpens[i]*i;
      open_sum_x  += i;
      open_sum_x2 += i*i;
    
      high_sum_y  += dblHighs[i];
      high_sum_xy += dblHighs[i]*i;
      high_sum_x  += i;
      high_sum_x2 += i*i;
    
      low_sum_y  += dblLows[i];
      low_sum_xy += dblLows[i]*i;
      low_sum_x  += i;
      low_sum_x2 += i*i;
    
      close_sum_y  += dblCloses[i];
      close_sum_xy += dblCloses[i]*i;
      close_sum_x  += i;
      close_sum_x2 += i*i;
    }
    
    open_c  = open_sum_x2  * intMaxStore - open_sum_x  * open_sum_x;
    high_c  = high_sum_x2  * intMaxStore - high_sum_x  * high_sum_x;
    low_c   = low_sum_x2   * intMaxStore - low_sum_x   * low_sum_x;
    close_c = close_sum_x2 * intMaxStore - close_sum_x * close_sum_x;
    
    //Find line equation
    if(open_c == 0 || high_c == 0 || low_c == 0 || close_c == 0)
    {
        Print("Constant C finding error");
        return;
    }
    
    // Line equation  
    dblOpen_m = (open_sum_xy * intMaxStore - open_sum_x * open_sum_y)/open_c;
    dblOpen_c = (open_sum_y  - open_sum_x * dblOpen_m) / intMaxStore;
    
    dblHigh_m = (high_sum_xy * intMaxStore - high_sum_x * high_sum_y)/high_c;
    dblHigh_c = (high_sum_y  - high_sum_x * dblHigh_m) / intMaxStore;
    
    dblLow_m = (low_sum_xy * intMaxStore - low_sum_x * low_sum_y)/low_c;
    dblLow_c = (low_sum_y  - low_sum_x * dblLow_m) / intMaxStore;
    
    dblClose_m = (close_sum_xy * intMaxStore - close_sum_x * close_sum_y)/close_c;
    dblClose_c = (close_sum_y  - close_sum_x * dblClose_m) / intMaxStore;
    
    StoreArray(dblOpen_m, dblOpen_ms,intMaxStore,true);
    StoreArray(dblHigh_m, dblHigh_ms,intMaxStore,true);
    StoreArray(dblLow_m,  dblLow_ms,intMaxStore,true);
    StoreArray(dblClose_m,dblClose_ms,intMaxStore,true);
    
    //FILL THE LINE
    ArrayResize(dblOpen_LR,intMaxStore);
    ArrayResize(dblHigh_LR,intMaxStore);
    ArrayResize(dblLow_LR,intMaxStore);
    ArrayResize(dblClose_LR,intMaxStore);
    
    for(int i = 0; i < intMaxStore; i++)
    {
      dblOpen_LR[i]  = dblOpen_m  * i + dblOpen_c;
      dblHigh_LR[i]  = dblHigh_m  * i + dblHigh_c;
      dblLow_LR[i]   = dblLow_m   * i + dblLow_c;
      dblClose_LR[i] = dblClose_m * i + dblClose_c;
      //LR_line[x]=a+b*x;
    }
}

void clsLinearRegression::FindTrend(void)
{
    if(ArraySize(dblOpen_LR) != intMaxStore) return;
    
    intOpenTrend  = dblOpen_LR[0] > dblOpen_LR[1] ? 1 : 2;
    intHighTrend  = dblHigh_LR[0] > dblHigh_LR[1] ? 1 : 2;
    intLowTrend   = dblLow_LR[0] > dblLow_LR[1] ? 1 : 2;
    intCloseTrend = dblClose_LR[0] > dblClose_LR[1] ? 1 : 2;
}