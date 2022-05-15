#include  "MASTER_INDI.mqh"

class clsDiffClose : 
     public  clsMasterIndi
{
     public:
                        clsDiffClose(string strInputSymbol,int intInputTF);
                        ~clsDiffClose();
        void            Updater(datetime time, bool preloop=false);
     
     protected:
     
        void            Oninit();
     
     private:
        double          dblBuyingPressure;
        double          dblATR;
        double          ArrDiff[];
        double          dblDiff;
        double          dblDiff_6;
        double          dblDiff_12;
        double          dblDiff_18;
        //FUNCTION
        void            FindBuyingPressure(int bar);
        void            FindATR(int bar);
        void            FindDiff(int bar);
        
        
};

clsDiffClose::clsDiffClose(string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
{
     this.Oninit();
}

clsDiffClose::~clsDiffClose(){}

void clsDiffClose::Oninit(void)
{
     this.intMaxStore = 18;
}

void clsDiffClose::Updater(datetime time, bool preloop=false)
{  
     int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
}


void clsDiffClose::FindATR(int bar)
{
     this.dblATR = iATR(this.strSymbol,this.intPeriod,14,bar);
}

void clsDiffClose::FindBuyingPressure(int bar)
{
     double close_1 = iClose(this.strSymbol,this.intPeriod,bar+1);
     double close_2 = iClose(this.strSymbol,this.intPeriod,bar+2);
     this.dblBuyingPressure = close_1 - close_2;
}

void clsDiffClose::FindDiff(int bar)
{
     this.dblDiff = this.dblBuyingPressure - this.dblATR;
     this.StoreArray(this.dblDiff,this.ArrDiff,this.intMaxStore);
     if(ArraySize(this.ArrDiff) >= this.intMaxStore)
     {
          //double arr_temp[] = ArraySetAsSeries(this.ArrDiff,);
          
     } 
}
