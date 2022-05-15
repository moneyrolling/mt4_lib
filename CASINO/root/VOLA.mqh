#include  "MASTER_INDI.mqh"
#include  "MASTER_CONFIG.mqh"
extern int vola_lookback = 9;

class clsVola: 
     public  clsMasterIndi
{
     public:
                         clsVola(string strInputSymbol, int intInputTF);
                         ~clsVola();
         void            Updater(datetime time, bool preloop=false);
         double          dblVola_6;
         double          dblVola_10;
         double          dblVola_100;
         int             intMaxRangeDirection;
     
     protected:
         void            Oninit();
         void            FindLargestRangeDirection(int start_bar, int bar_lookback);
     
     private:
         string          strIdentifier;
         
};

clsVola::clsVola(string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
{
  Print("Constructor at Child ",strInputSymbol);
  //this.CALL_FROM_FIBO = fibo_call;
  this.Oninit();
}

clsVola::~clsVola(void){}

void clsVola::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"VOLA"+(string)this.intPeriod;
    intMaxStore = 400; 
}

void clsVola::Updater(datetime time,bool preloop=false)
{
   //Alert("Creating Label at ",this.intPeriod);
   int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
   dblVola_6      = iATR(strSymbol,intPeriod,6,latest_bar);
   dblVola_10     = iATR(strSymbol,intPeriod,10,latest_bar);
   dblVola_100    = iATR(strSymbol,intPeriod,100,latest_bar);
   FindLargestRangeDirection(latest_bar,vola_lookback);
}

void clsVola::FindLargestRangeDirection(int start_bar, int bar_lookback)
{
   double max_range = DBL_MIN;
   int    max_range_bar = -1;
   for(int i = start_bar; i < start_bar + bar_lookback; i++)
   {
        double range = MathAbs(iClose(strSymbol,PERIOD_D1,i) - iOpen(strSymbol,PERIOD_D1,i));
        if(range > max_range)
        {
             max_range = range;
             max_range_bar = i;
        }
   }
   if(max_range_bar != -1)
   {
        if(iClose(strSymbol,intPeriod,max_range_bar) > iOpen(strSymbol,intPeriod,max_range_bar))
        {
             intMaxRangeDirection = 1;
        }  
        else
        {
             if(iClose(strSymbol,intPeriod,max_range_bar) < iOpen(strSymbol,intPeriod,max_range_bar))
              {
                   intMaxRangeDirection = 2;
              }  
        }
   }
}