#include  "STRUCTURE_NEW.mqh"
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
extern string _tmp2_ = "===== FIBO SETTINGS =====";
extern color fibo_color = clrMagenta;
extern FIBO_TRADE_INPUT FIBO_UP = FIBO382;
extern FIBO_TRADE_INPUT FIBO_DN = FIBO500;
struct STRUCTFIBO
{
    bool   _active;
    int    _type;
    int    _BOSIdx;
    int    _FIBOHighIdx;
    int    _FIBOLowIdx;
    double _FIBOHighValue;
    double _FIBOLowValue;
    double _FIBO000Value;
    double _FIBO236Value;
    double _FIBO382Value;
    double _FIBO500Value;
    double _FIBO618Value;
    double _FIBO702Value;
    double _FIBO786Value;
    double _FIBO100Value;
    
    STRUCTFIBO() : _active(false), _type(0), _BOSIdx(0), _FIBOHighIdx(0), _FIBOLowIdx(0), _FIBOHighValue(0), _FIBOLowValue(0),_FIBO000Value(0),_FIBO236Value(0), _FIBO382Value(0), _FIBO500Value(0), 
                   _FIBO618Value(0), _FIBO702Value(0), _FIBO786Value(0), _FIBO100Value(0)
                  {};
};


class clsFibo: 
     public  clsMasterIndi
{
     public:
                         clsFibo(string strInputSymbol, int intInputTF);
                         ~clsFibo();
         void            Updater(datetime time, bool preloop=false);
         void            DeleteFibo();
         int             arr_intStructureTrend[];
         int             arr_intStructureIndex[];
         int             arr_intBOSActive[];
         int             arr_intBOSHighIdx[];
         int             arr_intBOSLowIdx[];
         int             arr_intBOSIdx[];
         double          arr_dblBOSHigh[];
         double          arr_dblBOSLow[];
         double          arr_dblFiboRatio[8];
         double          arr_dblFiboLvlLabel[8];
         double          arr_dblFiboValue[8];
         STRUCTFIBO      CUR_FIBO;
         bool            EA_MODE;
         int             intFiboLookBack;
     
     protected:
         void            Oninit();
         void            DeclareFiboLevel();
         void            PreCalculateStructure(int bar);
         void            FindCurrentFibo(int bar);
         void            DrawFibo();
         void            EquateFiboRatio(string name);
     
     private:
         string          strIdentifier;
         //int             arr_intStructureTrend[];
         clsStructure    *STRUCTURE;
         
     
};

clsFibo::clsFibo(string strInputSymbol,int intInputTF):
      clsMasterIndi(strInputSymbol,intInputTF)
{
      Print("FIBO Constructor at Child ",strInputSymbol, " with TF ",this.intPeriod);
      this.Oninit();
}

clsFibo::~clsFibo()
{
      if(CheckPointer(this.STRUCTURE)==POINTER_DYNAMIC) delete STRUCTURE;
      Print("Prepare Delete Fibo at TF ",this.intPeriod);
      this.DeleteFibo();
}

void clsFibo::Oninit(void)
{
    STRUCTURE = new clsStructure(this.strSymbol,this.intPeriod,true);
    this.strIdentifier = (string)this.intPeriod+this.strSymbol+"FIBO";
    //STRUCTURE.strIdentifier = this.strIdentifier;
    this.EA_MODE = false;
    this.intMaxStore   = LOOKBACK;
    this.intFiboLookBack = LOOKBACK;
    this.DeclareFiboLevel();
}

void clsFibo::DeclareFiboLevel()
{
    //we need hard rule to decode
    this.arr_dblFiboRatio[0] = 0;
    this.arr_dblFiboRatio[1] = 0.236;
    this.arr_dblFiboRatio[2] = 0.382;
    this.arr_dblFiboRatio[3] = 0.50;
    this.arr_dblFiboRatio[4] = 0.618;
    this.arr_dblFiboRatio[5] = 0.702;
    this.arr_dblFiboRatio[6] = 0.786;
    this.arr_dblFiboRatio[7] = 1.0;
}

void clsFibo::DeleteFibo(void)
{
   
   for (int i=ObjectsTotal()-1; i >= 0; i--) 
   {
      string obj_name = ObjectName(i); 
      if(StringFind(obj_name,this.strIdentifier)>=0)
      {
          //Print("Deleting ",obj_name);
          ObjectDelete(0,obj_name);
      }
   }
   ChartRedraw();
}

void clsFibo::Updater(datetime time,bool preloop=false)
{
   
   int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
   Print("Fibo exist with latest bar ",latest_bar);
   this.PreCalculateStructure(latest_bar);
   this.FindCurrentFibo(latest_bar);
   if(ChartSymbol() == this.strSymbol && ChartPeriod() == this.intPeriod)
   {
      this.DrawFibo();
   }
}

void clsFibo::PreCalculateStructure(int bar)
{  
    int bar_look = this.EA_MODE == False ? LOOKBACK : this.intFiboLookBack;
    for(int i = bar + bar_look - 1; i >= bar; i--)
    {
          //Print("Storing Fibo Structure of ",i);
          datetime time_i = iTime(this.strSymbol,this.intPeriod,i);
          this.STRUCTURE.Updater(time_i);
          //DO THE STORING FUNCTION
          this.StoreArray(this.STRUCTURE.intTrend,this.arr_intStructureTrend,this.intMaxStore,true);
          this.StoreArray(i,this.arr_intStructureIndex,this.intMaxStore,true);
          int   bos_active     = this.STRUCTURE.BOS._active ? 1 : 0;
          double bos_high      = this.STRUCTURE.BOS._active ? this.STRUCTURE.BOS._high : 0;
          double bos_low       = this.STRUCTURE.BOS._active ? this.STRUCTURE.BOS._low : 0;
          int    bos_idx       = this.STRUCTURE.BOS._active ? this.STRUCTURE.BOS._BOS_index : 0;
          int    bos_high_idx  = this.STRUCTURE.BOS._active ? this.STRUCTURE.BOS._high_index : 0;
          int    bos_low_idx   = this.STRUCTURE.BOS._active ? this.STRUCTURE.BOS._low_index : 0;
          this.StoreArray(bos_active,   this.arr_intBOSActive,this.intMaxStore,true);
          this.StoreArray(bos_high_idx, this.arr_intBOSHighIdx,this.intMaxStore,true);
          this.StoreArray(bos_low_idx,  this.arr_intBOSLowIdx,this.intMaxStore,true);
          this.StoreArray(bos_idx    ,  this.arr_intBOSIdx,this.intMaxStore,true);
          this.StoreArray(bos_high,     this.arr_dblBOSHigh,this.intMaxStore,true);
          this.StoreArray(bos_low,      this.arr_dblBOSLow,this.intMaxStore,true);
    }
}

void clsFibo::FindCurrentFibo(int bar)
{
   this.DeleteFibo();
   for(int i = ArraySize(this.arr_intStructureIndex)-1; i >= 0; i--)
   {
        int cur_index    = this.arr_intStructureIndex[i];
        //Print("Array Size of bos high is ",ArraySize(this.arr_intBOSHighIdx));
        //Print("I is ",i);
        if(this.arr_intBOSActive[i] == 1 && this.arr_intBOSIdx[i] > 0 && this.arr_intBOSHighIdx[i] > 0 && this.arr_intBOSLowIdx[i] > 0)
        {
             int bos_index    = this.arr_intBOSIdx[i];
             //no fibo initiated yet
             if(this.CUR_FIBO._active == 0)
             {
                  //Print("First BOS at ",bos_index);
                  //Print("Current Index is ",cur_index);
                  int fibo_high_idx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,bos_index - cur_index + 1,cur_index);
                  int fibo_low_idx  = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,bos_index - cur_index + 1,cur_index);
                  double fibo_high  = iHigh(this.strSymbol,this.intPeriod,fibo_high_idx);
                  double fibo_low   = iLow(this.strSymbol,this.intPeriod,fibo_low_idx);
                  //REGISTER A NEW FIBO
                  //REMEMBER RESET VALUE FIRST
                  STRUCTFIBO empty_fibo;
                  this.CUR_FIBO = empty_fibo;
                  this.CUR_FIBO._active = true;
                  this.CUR_FIBO._type   = fibo_high_idx <= fibo_low_idx ? 1 : 2;
                  this.CUR_FIBO._BOSIdx = bos_index;
                  this.CUR_FIBO._FIBOHighIdx   = fibo_high_idx;
                  this.CUR_FIBO._FIBOLowIdx    = fibo_low_idx;
                  this.CUR_FIBO._FIBOHighValue = fibo_high;
                  this.CUR_FIBO._FIBOLowValue  = fibo_low;
                  //Print("First Fibo Type is ",this.CUR_FIBO._type);
                  //Print("First Fibo High Index is ",this.CUR_FIBO._FIBOHighIdx);
                  //Print("First Fibo Low Index is ",this.CUR_FIBO._FIBOLowIdx);
              }
             
             int fib_high_idx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH);
        }
        
        if(this.CUR_FIBO._active == 1)
        {
             //active fibo, to check and update accordingly
             double cur_high = iHigh(this.strSymbol,this.intPeriod,cur_index);
             double cur_low  = iLow(this.strSymbol,this.intPeriod,cur_index);
             double fibo_50  = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)/2;
             
             this.CUR_FIBO._FIBO500Value = fibo_50;
             if(this.CUR_FIBO._type == 1)
             {
                 this.CUR_FIBO._FIBO000Value = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.000;
                 this.CUR_FIBO._FIBO236Value = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.236;
                 this.CUR_FIBO._FIBO382Value = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.382;
                 this.CUR_FIBO._FIBO618Value = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.618;
                 this.CUR_FIBO._FIBO702Value = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.702;
                 this.CUR_FIBO._FIBO786Value = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.786;
                 this.CUR_FIBO._FIBO100Value = this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*1.000;
                 /*
                 if(cur_index < 70)
                 {
                    Print("Checking type 1 fibo");
                    //Print("Current Low is ",cur_low);
                    Print("Current FIBO Low Idx is ",this.CUR_FIBO._FIBOLowIdx);
                    //Print("Current FIBO Low is ",this.CUR_FIBO._FIBOLowValue);
                    Print("Current FIBO High Idx is ",this.CUR_FIBO._FIBOHighIdx);
                    Print("Current FIBO High is ",this.CUR_FIBO._FIBOHighValue);
                    Print("Current Index is ",cur_index);
                    //we check update of fibo only when the price higher than fibo high
                 }
                 */
                 //we check update of fibo only when the price higher than fibo high
                 if(cur_high > this.CUR_FIBO._FIBOHighValue)
                 {
                    //find post peak low, wehether retrace > 50%
                    int post_fibo_low_idx = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,this.CUR_FIBO._FIBOHighIdx - cur_index + 1,cur_index);
                    double post_fibo_low = iLow(this.strSymbol,this.intPeriod,post_fibo_low_idx);
                    if(post_fibo_low < fibo_50 && this.CUR_FIBO._FIBOHighIdx - post_fibo_low_idx > 1)
                    {
                        //we need to form a new FIBO post break high
                        //this.CUR_FIBO._BOSIdx = this.CUR_FIBO._FIBOHighIdx; //we replace the BOS with ex high
                        this.CUR_FIBO._BOSIdx = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,this.CUR_FIBO._FIBOHighIdx - cur_index + 1,cur_index);//we use lowest point between new high and old high as new BOS
                    }
                    //else we just update how 
                    int fibo_high_idx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.CUR_FIBO._BOSIdx - cur_index + 1,cur_index);
                    int fibo_low_idx  = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,this.CUR_FIBO._BOSIdx - cur_index + 1,cur_index);
                    double fibo_high  = iHigh(this.strSymbol,this.intPeriod,fibo_high_idx);
                    double fibo_low   = iLow(this.strSymbol,this.intPeriod,fibo_low_idx);
                    this.CUR_FIBO._FIBOHighIdx   = fibo_high_idx;
                    this.CUR_FIBO._FIBOLowIdx    = fibo_low_idx;
                    this.CUR_FIBO._FIBOHighValue = fibo_high;
                    this.CUR_FIBO._FIBOLowValue  = fibo_low;
                  }
                  //we delete the fibo, wait for fibo formed on next new BOS
                  if(cur_low < this.CUR_FIBO._FIBOLowValue)
                  {
                       //RESET FIBO
                       STRUCTFIBO empty_fibo;
                       this.CUR_FIBO = empty_fibo;
                       Print("Deactivating BULL Fibo",cur_index);
                  }
             }
             
             else
             {
                if(this.CUR_FIBO._type == 2)
                {  
                    this.CUR_FIBO._FIBO000Value = this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.000;
                    this.CUR_FIBO._FIBO236Value = this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.236;
                    this.CUR_FIBO._FIBO382Value = this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.382;
                    this.CUR_FIBO._FIBO618Value = this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.618;
                    this.CUR_FIBO._FIBO702Value = this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.702;
                    this.CUR_FIBO._FIBO786Value = this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*0.786;
                    this.CUR_FIBO._FIBO100Value = this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue)*1.000;
             
                    if(cur_low < this.CUR_FIBO._FIBOLowValue)
                    {
                       //find post peak low, wehether retrace > 50%
                       int post_fibo_high_idx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.CUR_FIBO._FIBOLowIdx - cur_index + 1,cur_index);
                       double post_fibo_high = iHigh(this.strSymbol,this.intPeriod,post_fibo_high_idx);
                       //Print("Post Fibo High Index is ",iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.CUR_FIBO._FIBOLowIdx - cur_index + 1,cur_index));
                       if(post_fibo_high > fibo_50 && this.CUR_FIBO._FIBOLowIdx - post_fibo_high_idx > 1)
                       {
                           //we need to form a new FIBO post break high
                           //this.CUR_FIBO._BOSIdx = this.CUR_FIBO._FIBOLowIdx; //we replace the BOS with ex high
                           Print("Fibo Half is ",fibo_50);
                           Print("Post Fibo High Index Is ",iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.CUR_FIBO._FIBOLowIdx - cur_index + 1,cur_index));
                           Print("Post Fibo High Is ",post_fibo_high);
                           Print("I switch bos index");
                           this.CUR_FIBO._BOSIdx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.CUR_FIBO._FIBOLowIdx - cur_index + 1,cur_index);//we use highest point between new low and old low as new BOS
                       }
                       //else we just update how 
                       int fibo_high_idx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.CUR_FIBO._BOSIdx - cur_index + 1,cur_index);
                       int fibo_low_idx  = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,this.CUR_FIBO._BOSIdx - cur_index + 1,cur_index);
                       double fibo_high  = iHigh(this.strSymbol,this.intPeriod,fibo_high_idx);
                       double fibo_low   = iLow(this.strSymbol,this.intPeriod,fibo_low_idx);
                       this.CUR_FIBO._FIBOHighIdx   = fibo_high_idx;
                       this.CUR_FIBO._FIBOLowIdx    = fibo_low_idx;
                       this.CUR_FIBO._FIBOHighValue = fibo_high;
                       this.CUR_FIBO._FIBOLowValue  = fibo_low;
                     }
                     //we delete the fibo, wait for fibo formed on next new BOS
                     if(cur_high > this.CUR_FIBO._FIBOHighValue)
                     {
                          //RESET FIBO
                          STRUCTFIBO empty_fibo;
                          this.CUR_FIBO = empty_fibo;
                          Print("Deactivating BEAR Fibo at ",cur_index);
                     }
                }
             }
        }
        
   }
}

void clsFibo::EquateFiboRatio(string name)
{
   //find level first
   for(int i = 0; i < ArraySize(this.arr_dblFiboRatio); i++)
   {
        switch(this.CUR_FIBO._type)
        {
              case 1 :
                  this.arr_dblFiboValue[i]    = NormalizeDouble(this.CUR_FIBO._FIBOHighValue - (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue) * this.arr_dblFiboRatio[i],(int)MarketInfo(this.strSymbol,MODE_DIGITS));
                  //Print("Responding Bull value is ",this.arr_dblFiboValue[i]);
                  this.arr_dblFiboLvlLabel[i] = this.arr_dblFiboRatio[i] * 100;
                  //--- level value
                  ObjectSetDouble(0,name,OBJPROP_LEVELVALUE,i,this.arr_dblFiboRatio[i]); //set fibo price value on chart
                  //ObjectSetDouble(0,name,OBJPROP_LEVELVALUE,i,this.arr_dblFiboValue[i]); //set fibo price value on chart
                  //--- level description
                  ObjectSetString(0,name,OBJPROP_LEVELTEXT,i,DoubleToString(this.arr_dblFiboLvlLabel[i]));//set text
                  //--- level color
                  ObjectSetInteger(0,name,OBJPROP_LEVELCOLOR,i,fibo_color);
                  //--- level style
                  ObjectSetInteger(0,name,OBJPROP_LEVELSTYLE,i,STYLE_SOLID);
                  //--- level width
                  ObjectSetInteger(0,name,OBJPROP_LEVELWIDTH,i,1);
                  break;
              case 2:
                  this.arr_dblFiboValue[i]    = NormalizeDouble(this.CUR_FIBO._FIBOLowValue + (this.CUR_FIBO._FIBOHighValue - this.CUR_FIBO._FIBOLowValue) * this.arr_dblFiboRatio[i],(int)MarketInfo(this.strSymbol,MODE_DIGITS));
                  //Print("Responding Bear value is ",this.arr_dblFiboValue[i]);
                  this.arr_dblFiboLvlLabel[i] = this.arr_dblFiboRatio[i] * 100;
                  //--- level value
                  ObjectSetDouble(0,name,OBJPROP_LEVELVALUE,i,this.arr_dblFiboRatio[i]); 
                  //ObjectSetDouble(0,name,OBJPROP_LEVELVALUE,i,this.arr_dblFiboValue[i]); //set fibo price value on chart
                  //--- level description
                  ObjectSetString(0,name,OBJPROP_LEVELTEXT,i,DoubleToString(this.arr_dblFiboLvlLabel[i]));//set text
                  //--- level color
                  ObjectSetInteger(0,name,OBJPROP_LEVELCOLOR,i,fibo_color);
                  //--- level style
                  ObjectSetInteger(0,name,OBJPROP_LEVELSTYLE,i,STYLE_SOLID);
                  //--- level width
                  ObjectSetInteger(0,name,OBJPROP_LEVELWIDTH,i,1);
                  break;
        }
   }
}



void clsFibo::DrawFibo(void)
{
   this.DeleteFibo();
   WindowRedraw();
   if(this.CUR_FIBO._active == 1)
   {
        Print("Drawing Fibo");
        string ob_name = this.strIdentifier + "_Fibo";
        if(this.CUR_FIBO._type ==1)
        {
             datetime time1   = iTime(this.strSymbol,this.intPeriod,this.CUR_FIBO._FIBOLowIdx);
             datetime time2   = iTime(this.strSymbol,this.intPeriod,this.CUR_FIBO._FIBOHighIdx);
             double   price1  = this.CUR_FIBO._FIBOLowValue;
             double   price2  = this.CUR_FIBO._FIBOHighValue;
             color    fibclr  = BOS_LINE_UP;
             ObjectCreate(0,ob_name,OBJ_FIBO,0,time1,price1,time2,price2); //Create fibo function
             ObjectSetInteger(0,ob_name,OBJPROP_COLOR,fibo_color);
             ObjectSetInteger(0,ob_name,OBJPROP_STYLE,STYLE_DOT);
             ObjectSetInteger(0,ob_name,OBJPROP_WIDTH,1);
             ObjectSetInteger(0,ob_name,OBJPROP_SELECTABLE,false);
             ObjectSetInteger(0,ob_name,OBJPROP_SELECTED,false);
             ObjectSetInteger(0,ob_name,OBJPROP_BACK,false);
             ObjectSetInteger(0,ob_name,OBJPROP_RAY_RIGHT,true);
             ObjectSetInteger(0,ob_name,OBJPROP_HIDDEN,false);
             ObjectSetInteger(0,ob_name,OBJPROP_LEVELS,ArraySize(this.arr_dblFiboRatio));
             this.EquateFiboRatio(ob_name);
        }
        if(this.CUR_FIBO._type ==2)
        {
             datetime time2   = iTime(this.strSymbol,this.intPeriod,this.CUR_FIBO._FIBOLowIdx);
             datetime time1   = iTime(this.strSymbol,this.intPeriod,this.CUR_FIBO._FIBOHighIdx);
             double   price2  = this.CUR_FIBO._FIBOLowValue;
             double   price1  = this.CUR_FIBO._FIBOHighValue;
             color    fibclr  = BOS_LINE_DN;
             ObjectCreate(0,ob_name,OBJ_FIBO,0,time1,price1,time2,price2); //Create fibo function
             ObjectSetInteger(0,ob_name,OBJPROP_COLOR,fibo_color);
             ObjectSetInteger(0,ob_name,OBJPROP_STYLE,STYLE_DOT);
             ObjectSetInteger(0,ob_name,OBJPROP_WIDTH,1);
             ObjectSetInteger(0,ob_name,OBJPROP_SELECTABLE,false);
             ObjectSetInteger(0,ob_name,OBJPROP_SELECTED,false);
             ObjectSetInteger(0,ob_name,OBJPROP_BACK,false);
             ObjectSetInteger(0,ob_name,OBJPROP_RAY_RIGHT,true);
             ObjectSetInteger(0,ob_name,OBJPROP_HIDDEN,false);
             ObjectSetInteger(0,ob_name,OBJPROP_LEVELS,ArraySize(this.arr_dblFiboRatio));
             this.EquateFiboRatio(ob_name);
        }
   }
}

