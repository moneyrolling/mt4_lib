#include  "MASTER_INDI.mqh"
#include  "MASTER_CONFIG.mqh"
input int MMI_Count = 300;


class clsMMI : 
     public  clsMasterIndi
{
   public:
     
              clsMMI(string strInputSymbol, int intInputTF);
              ~clsMMI();
     void     Updater(datetime time,bool preloop=false);
     double   dblMedian;
     double   dblMMI;
   
   protected:
     void    Oninit();
     void    FindFractal();
     void    LoopCustomOHLC(int bar);
     void    FindMedian(double &datas[]);
     void    FindMMI(double &datas[]);
   
   private:
     string  strIdentifier;
     
};

clsMMI::clsMMI(string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
{
  Print("Constructor MMI at Child ",strInputSymbol);
  //this.CALL_FROM_FIBO = fibo_call;
  this.Oninit();
}

clsMMI::~clsMMI(void){}

void clsMMI::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"MMI"+(string)this.intPeriod;
    intMaxStore = MMI_Count;
    dblMMI      = 888; 
    Preloop();
}

void clsMMI::Updater(datetime time,bool preloop=false)
{
   //Alert("Creating Label at ",this.intPeriod);
   int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
   //Print("Looping at bar of ",latest_bar);
   LoopCustomOHLC(latest_bar);
   FindMedian(Closes);
   FindMMI(Closes);
}

void clsMMI::LoopCustomOHLC(int bar)
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
    
    int count = intMaxStore - 1;
    for(int i = bar + intMaxStore - 1; i >= bar; i--)
    {
         if(iOpen(strSymbol,intPeriod,i) == 0)
         {
             Alert("Historical Data BackLoop Not Enough, Skipping...");
             break;
         }
         //Alert("Looping i of ",i);
         Opens[count]   = iOpen(strSymbol,intPeriod,i);
         Highs[count]   = iHigh(strSymbol,intPeriod,i);
         Lows[count]    = iLow (strSymbol,intPeriod,i);
         Closes[count]  = iClose(strSymbol,intPeriod,i);
         Times[count]   = iTime(strSymbol,intPeriod,i);
         count--;
    }
}

void clsMMI::FindMedian(double &datas[])
{
    if(ArraySize(datas) != intMaxStore) return;
    double max = ArrayMaximum(datas);
    double min = ArrayMinimum(datas);
    dblMedian  = (max + min)/2;
}

void clsMMI::FindMMI(double &datas[])
{
    int nl = 0;
    int nh = 0;
    for(int i=1; i<intMaxStore; i++) 
    {
       if(datas[i] > dblMedian && datas[i] > datas[i-1]) // mind Data order: Data[0] is newest!
       {  nl++; }
       else if(datas[i] < dblMedian && datas[i] < datas[i-1])
       {  nh++; }
    }
    dblMMI = 100.*(nl+nh)/(intMaxStore-1);
}