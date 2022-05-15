#include  "MASTER_INDI.mqh"
extern string _tmp0_ = "===== STRUCTURE SETTINGS =====";
extern int LOOKBACK = 200;
extern color BOS_LINE_UP = clrLimeGreen;
extern color BOS_LINE_DN = clrRed;
extern color STRUC_LABEL_COL = clrYellow;

struct STRUCTTREND
{
   int      _type; // 1 bull, 2 bear
   double   _high;
   double   _low;
   int      _high_index;
   int      _low_index;
   STRUCTTREND() : _type(0), _high(0), _low(0), _high_index(0), _low_index(0) {};
};

struct STRUCTBOS
{
   bool     _active;
   double   _high;
   int      _high_index;
   double   _low;
   int      _low_index;
   int      _prev_trend_type;
   double   _BOS_value;
   int      _BOS_index;
   double   _QML;
   int      _QML_index;
   //int      _BOS_type;
   STRUCTBOS() : _active(false), _high(0), _high_index(0), _low(0), _low_index(0), _prev_trend_type(0), _BOS_value(0), _BOS_index(0) {}; 
};

class clsStructure : 
     public  clsMasterIndi
{
   public:
                      clsStructure(string strInputSymbol, int intInputTF, bool fibo_call=false);
                      ~clsStructure();
      void            Updater(datetime time, bool preloop=false);
      void            CreateLabel();
      void            Find_Structure(int bar);
      double          dblFirstFractalHigh;
      int             intFirstFractalHighIndex;
      double          dblFirstFractalLow;
      int             intFirstFractalLowIndex;
      double          dblTrendHigh;
      double          dblTrendLow;
      int             intTrendHighIdx;
      int             intTrendLowIdx;
      int             intTrend; //initial is -1, BULL 1, BEAR 2, BOS 0
      int             intTrendArray[];
      STRUCTTREND     TREND_CURRENT;
      STRUCTTREND     TREND_PREVIOUS;
      STRUCTBOS       BOS;
      bool            EA_MODE;
      bool            CALL_FROM_FIBO;
      string          strIdentifier;
      
   protected:
      void            Oninit();
      void            ResetValue();
      
   private:
      
      void            DeleteLabel();
      void            PlotBOS(int bar);
      void            PlotQML(int bar);
      
      void            FindFirstFractals(int bar);
      
      int             FindSuccesiveFractal(int type, int left_idx, int right_idx);
      int             FindBosBreakFractal(int type, int left_idx,int right_idx);
      void            FindBosQML();
      void            DrawLabel(string name, int xCord, int yCord, string text);
      //STRUCTBOS       BOS;
      bool            blCheckTrendChange();
      
};

clsStructure::clsStructure(string strInputSymbol,int intInputTF, bool fibo_call=false):
        clsMasterIndi(strInputSymbol,intInputTF)
     {
        Print("Constructor at Child ",strInputSymbol);
        this.CALL_FROM_FIBO = fibo_call;
        this.Oninit();
     }
 
clsStructure::~clsStructure()
{
     Print("Check Structure Called From FIBO is ",this.CALL_FROM_FIBO);
     if(!this.CALL_FROM_FIBO) 
     {
       Print("Prepare to delete structure");
       this.DeleteLabel();
      //Comment("");
     }
}

void clsStructure::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"STR"+(string)this.intPeriod;
    this.EA_MODE = False;
}

bool clsStructure::blCheckTrendChange()
{
    int static prev_trend = -1;
    if(prev_trend == -1 || prev_trend != this.intTrend)
    {
         prev_trend = this.intTrend;
         return(true);
    }
    return(false);
}

void clsStructure::DeleteLabel(void)
{
   //Print("Prepare Delete");
   for (int i=ObjectsTotal()-1; i >= 0; i--) 
   {
      string obj_name = ObjectName(i); 
      if(StringFind(obj_name,this.strIdentifier)>=0)
      {
          //Print("Deleting ",this.strIdentifier);
          ObjectDelete(0,obj_name);
      }
   }
   ChartRedraw();
}



void clsStructure::Updater(datetime time,bool preloop=false)
{
   //Alert("Creating Label at ",this.intPeriod);
   int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
   this.FindFirstFractals(latest_bar);
   this.intTrend = -1;
   this.Find_Structure(latest_bar);
   if(this.blCheckTrendChange()) this.StoreArray(this.intTrend,this.intTrendArray,2);
   if(!this.CALL_FROM_FIBO)
   {
      
      if(this.strSymbol == ChartSymbol() && this.intPeriod == ChartPeriod())
      {
         this.DeleteLabel();
         this.PlotBOS(latest_bar);
         this.PlotQML(latest_bar);
         this.CreateLabel();
         //if(!EA_MODE){this.CreateLabel();}
         //else{if(this.intTrend == 0){this.CreateLabel();}}
      }
   }
}


void clsStructure::FindFirstFractals(int bar)
{
    if(this.dblFirstFractalHigh == 0)
    {
        for(int i = bar + LOOKBACK; i > bar; i--)
        {
             if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
             {
                 this.dblFirstFractalHigh = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                 this.intFirstFractalHighIndex = i;
                 break;
             }
        }
    }
    if(this.dblFirstFractalLow == 0)
    {
        for(int i = bar + LOOKBACK; i > bar; i--)
        {
             if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
             {
                 this.dblFirstFractalLow = iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                 this.intFirstFractalLowIndex = i;
                 break;
             }
        }
    }
    
}

void clsStructure::Find_Structure(int bar)
{
      //for(int i = 200; i >= bar; i--)
      for(int i = bar + LOOKBACK; i >= bar; i--)
      {
           if(this.intTrend == -1) //initial trend
           // 2 SCENARIOS : BREAK UP OR BREAK DOWN
           {
               //this is the first run, we have 2 possibilities, either break up or break down
               if(iHigh(this.strSymbol,this.intPeriod,i) > this.dblFirstFractalHigh)
               {
                    this.intTrend = 0; //BOS
                    this.BOS._active = true;
                    //we need register BOS High and Low
                    //BOS High just done, we need wait a valid HIGH to be registered
                    if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                    {
                         this.BOS._high = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                         this.BOS._high_index = i;
                    }
                    this.BOS._low = this.dblFirstFractalLow;
                    this.BOS._low_index = this.intFirstFractalLowIndex;
               }
               if(iLow(this.strSymbol,this.intPeriod,i) < this.dblFirstFractalLow)
               {    
                    this.intTrend = 0; //BOS
                    this.BOS._active = true;
                    //we need register BOS High and Low
                    //BOS High just done, we need wait a valid HIGH to be registered
                    if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                    {
                         this.BOS._low = iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                         this.BOS._low_index = i;
                    }
                    this.BOS._high = this.dblFirstFractalHigh;
                    this.BOS._high_index = this.intFirstFractalHighIndex;
                    
               }
           }
           
           else
           {
              if(this.intTrend == 0)
              {
                  // 3 TASKS
                  // A. Update the zero value BOS high low
                  // B. Check Break Up => Form BULL Trend => Find And Register Low Point  => Reset BOS
                  // C. Check Break Dn => Form BEAR Trend => Find And Register High Point => Reset BOS
                  
                  //BOS
                  //if(this.BOS._prev_trend_type == 0)
                  //{
                      //meaning post Init registration, we need to do something here
                      if(this.BOS._low == 0)
                      {
                           if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                           {
                                 this.BOS._low = iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                                 this.BOS._low_index = i;
                           }
                      }
                      if(this.BOS._high == 0)
                      {
                           if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                           {
                                 this.BOS._high = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                                 this.BOS._high_index = i;
                           }
                      }
                      if(this.BOS._high != 0 && this.BOS._low != 0)
                      {
                           //BOSS BOTH HIGH AND LOW PRESENT, WE FIND A BREAK AND TO SWITCH TO A TREND
                           
                           //A. Break Up
                           if(iHigh(this.strSymbol,this.intPeriod,i) > this.BOS._high)
                           {
                               //FROM BOS MOVE TO UP
                               this.intTrend = 1;
                               //we find and store the low
                               int lowest_idx    = this.FindBosBreakFractal(1,this.BOS._low_index,i);
                               //int lowest_idx    = this.BOS._low_index;
                               //int lowest_idx  = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,this.BOS._high_index- i + 1,i);
                               double lowest_val = iLow(this.strSymbol,this.intPeriod,lowest_idx);
                               this.dblTrendLow  = lowest_val;
                               this.intTrendLowIdx = lowest_idx;
                               this.dblTrendHigh     = 0;
                               this.intTrendHighIdx  = 0;
                               if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                               {
                                   this.dblTrendHigh = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                                   this.intTrendHighIdx = i;
                               }
                               //RESET BOS
                               STRUCTBOS emptybos;
                               this.BOS = emptybos;
                           }
                           //B. Break Down
                           else
                           {
                              if(iLow(this.strSymbol,this.intPeriod,i) < this.BOS._low)
                              {
                                  //FROM BOS MOVE TO DN
                                  this.intTrend = 2;
                                  //we find and store the low
                                  int highest_idx      = this.FindBosBreakFractal(2,this.BOS._high_index,i);
                                  //int highest_idx        = this.BOS._high_index;
                                  //int highest_idx      = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.BOS._low_index- i + 1,i);
                                  double highest_val   = iHigh(this.strSymbol,this.intPeriod,highest_idx);
                                  this.dblTrendHigh    = highest_val;
                                  this.intTrendHighIdx = highest_idx;
                                  this.dblTrendLow     = 0;
                                  this.intTrendLowIdx  = 0;
                                  if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                                  {
                                      this.dblTrendLow = iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                                      this.intTrendLowIdx = i;
                                      //return;
                                  }
                                  //RESET BOS
                                  STRUCTBOS  emptybos;
                                  this.BOS = emptybos;
                              }
                          }
                      }
                      
                  //}
              }
              else
              {
                    if(this.intTrend == 1)
                    {
                        // 3 TASKS
                        // A. Update the zero value TREND high low
                        // B. Check Break Up => Continue BULL Trend => Find And Register New Low Point 
                        // C. Check Break Dn => Form new BOS => Register BOS High Point => Activate BOS => Register trend as zero
                        if(this.dblTrendHigh == 0)  
                        {
                            if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                            {
                                 this.dblTrendHigh    = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                                 this.intTrendHighIdx = i;
                            }
                        }
                        if(this.dblTrendLow == 0)
                        {
                            if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                            {
                                 this.dblTrendLow =iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                                 this.intTrendLowIdx = i;
                            }
                        }
                        if(this.dblTrendHigh != 0 && this.dblTrendLow != 0)
                        {
                            if(iHigh(this.strSymbol,this.intPeriod,i) > this.dblTrendHigh)
                            {
                                 //Update latest trend low
                                 //Check first is it a fractal low, else we abandoned
                                 //Print("Checking Index Left ",this.intTrendHighIdx," Right ",i);
                                 //Print("Previous Low Index is ",this.intTrendLowIdx);
                                 int check_idx  = this.FindSuccesiveFractal(1,this.intTrendHighIdx,i);
                                 
                                 int lowest_idx = check_idx > 0 ? check_idx : this.intTrendLowIdx;
                                 //int lowest_idx      = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,this.intTrendHighIdx- i + 1,i);
                                 double lowest_val   = iLow(this.strSymbol,this.intPeriod,lowest_idx);
                                 this.dblTrendLow    = lowest_val;
                                 this.intTrendLowIdx = lowest_idx;
                                 //wait to reset trend value
                                 this.dblTrendHigh = 0;
                                 this.intTrendHighIdx = 0;
                                 //check trend high fractal if available
                                 if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                                 {
                                     this.dblTrendHigh = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                                     this.intTrendHighIdx = i;
                                 }
                                 
                            }
                            
                            if(iLow(this.strSymbol,this.intPeriod,i) < this.dblTrendLow)
                            {
                                 //FORM NEW BOS
                                 STRUCTBOS emptybos;
                                 this.BOS = emptybos;
                                 this.BOS._active = true;
                                 //BOS SETUP
                                 //Register bos high point first, leave the low blank
                                 this.BOS._high = this.dblTrendHigh;
                                 this.BOS._high_index = this.intTrendHighIdx;
                                 //Register Previous Trend
                                 this.BOS._prev_trend_type = this.intTrend;
                                 //Register BOS Value
                                 this.BOS._BOS_value = this.dblTrendLow;
                                 this.BOS._BOS_index = this.intTrendLowIdx;
                                 //FIND QML
                                 //this.FindBosQML();
                                 //Set Current Trend as zero
                                 this.intTrend = 0;
                            }
                            
                        }
                        
                    }
                    else
                    {
                       if(this.intTrend == 2)
                       {
                           // 3 TASKS
                           // A. Update the zero value TREND high low
                           // B. Check Break Dn => Continue BEAR Trend => Find And Register New High Point 
                           // C. Check Break Up => Form new BOS => Register BOS Low Point => Activate BOS => Register trend as zero
                           if(this.dblTrendHigh == 0)  
                           {
                               if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                               {
                                    this.dblTrendHigh    = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                                    this.intTrendHighIdx = i;
                               }
                           }
                           if(this.dblTrendLow == 0)
                           {
                               if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                               {
                                    this.dblTrendLow =iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                                    this.intTrendLowIdx = i;
                               }
                           }
                           if(this.dblTrendHigh != 0 && this.dblTrendLow != 0)
                           {
                               if(iLow(this.strSymbol,this.intPeriod,i) < this.dblTrendLow)
                               {
                                    //Update latest trend low
                                    //Print("Checking Index Left ",this.intTrendHighIdx," Right ",i);
                                    //Print("Previous Low Index is ",this.intTrendLowIdx);
                                    int check_idx        = this.FindSuccesiveFractal(2,this.intTrendLowIdx,i);
                                    int highest_idx      = check_idx > 0 ? check_idx : this.intTrendHighIdx;
                                    //int highest_idx      = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.intTrendLowIdx- i + 1,i);
                                    double highest_val   = iHigh(this.strSymbol,this.intPeriod,highest_idx);
                                    this.dblTrendHigh    = highest_val;
                                    this.intTrendHighIdx = highest_idx;
                                    //wait to reset trend value
                                    this.dblTrendLow = 0;
                                    this.intTrendLowIdx = 0;
                                    //check trend high fractal if available
                                    if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                                    {
                                        this.dblTrendLow = iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                                        this.intTrendLowIdx = i;
                                    }
                                    
                               }
                               
                               if(iHigh(this.strSymbol,this.intPeriod,i) > this.dblTrendHigh)
                               {
                                    //FORM NEW BOS
                                    STRUCTBOS emptybos;
                                    this.BOS = emptybos;
                                    this.BOS._active = true;
                                    //BOS SETUP
                                    //Register bos low point first, leave the high blank
                                    this.BOS._low = this.dblTrendLow;
                                    this.BOS._low_index = this.intTrendLowIdx;
                                    //Register Previous Trend
                                    this.BOS._prev_trend_type = this.intTrend;
                                    //Register BOS Value
                                    this.BOS._BOS_value = this.dblTrendHigh;
                                    this.BOS._BOS_index = this.intTrendHighIdx;
                                    //FIND QML
                                    //this.FindBosQML();
                                    //Set Current Trend as zero
                                    this.intTrend = 0;
                               }
                               
                           }
                           
                       }
                    }
              }
           }
           /*
           if(this.intTrend == 1)
           {
               // 3 TASKS
               // A. Update the zero value TREND high low
               // B. Check Break Up => Continue BULL Trend => Find And Register New Low Point 
               // C. Check Break Dn => Form new BOS => Register BOS High Point => Activate BOS => Register trend as zero
               if(this.dblTrendHigh == 0)  
               {
                   if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                   {
                        this.dblTrendHigh    = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                        this.intTrendHighIdx = i;
                   }
               }
               if(this.dblTrendLow == 0)
               {
                   if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                   {
                        this.dblTrendLow =iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                        this.intTrendLowIdx = i;
                   }
               }
               if(this.dblTrendHigh != 0 && this.dblTrendLow != 0)
               {
                   if(iHigh(this.strSymbol,this.intPeriod,i) > this.dblTrendHigh)
                   {
                        //Update latest trend low
                        int lowest_idx      = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,this.intTrendHighIdx- i + 1,i);
                        double lowest_val   = iLow(this.strSymbol,this.intPeriod,lowest_idx);
                        this.dblTrendLow    = lowest_val;
                        this.intTrendLowIdx = lowest_idx;
                        //wait to reset trend value
                        this.dblTrendHigh = 0;
                        //check trend high fractal if available
                        if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                        {
                            this.dblTrendHigh = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                        }
                        
                   }
                   
                   if(iLow(this.strSymbol,this.intPeriod,i) < this.dblTrendLow)
                   {
                        //FORM NEW BOS
                        STRUCTBOS emptybos;
                        this.BOS = emptybos;
                        this.BOS._active = true;
                        //BOS SETUP
                        //Register bos high point first, leave the low blank
                        this.BOS._high = this.dblTrendHigh;
                        this.BOS._high_index = this.intTrendHighIdx;
                        //Register Previous Trend
                        this.BOS._prev_trend_type = this.intTrend;
                        //Register BOS Value
                        this.BOS._BOS_value = this.dblTrendLow;
                        //Set Current Trend as zero
                        this.intTrend = 0;
                   }
                   
               }
               
           }
           
           if(this.intTrend == 2)
           {
               // 3 TASKS
               // A. Update the zero value TREND high low
               // B. Check Break Dn => Continue BEAR Trend => Find And Register New High Point 
               // C. Check Break Up => Form new BOS => Register BOS Low Point => Activate BOS => Register trend as zero
               if(this.dblTrendHigh == 0)  
               {
                   if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                   {
                        this.dblTrendHigh    = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                        this.intTrendHighIdx = i;
                   }
               }
               if(this.dblTrendLow == 0)
               {
                   if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                   {
                        this.dblTrendLow =iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                        this.intTrendLowIdx = i;
                   }
               }
               if(this.dblTrendHigh != 0 && this.dblTrendLow != 0)
               {
                   if(iLow(this.strSymbol,this.intPeriod,i) < this.dblTrendLow)
                   {
                        //Update latest trend low
                        int highest_idx      = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,this.intTrendLowIdx- i + 1,i);
                        double highest_val   = iHigh(this.strSymbol,this.intPeriod,highest_idx);
                        this.dblTrendHigh    = highest_val;
                        this.intTrendHighIdx = highest_idx;
                        //wait to reset trend value
                        this.dblTrendLow = 0;
                        //check trend high fractal if available
                        if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                        {
                            this.dblTrendLow = iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                        }
                        
                   }
                   
                   if(iHigh(this.strSymbol,this.intPeriod,i) > this.dblTrendHigh)
                   {
                        //FORM NEW BOS
                        STRUCTBOS emptybos;
                        this.BOS = emptybos;
                        this.BOS._active = true;
                        //BOS SETUP
                        //Register bos low point first, leave the high blank
                        this.BOS._low = this.dblTrendLow;
                        this.BOS._low_index = this.intTrendLowIdx;
                        //Register Previous Trend
                        this.BOS._prev_trend_type = this.intTrend;
                        //Register BOS Value
                        this.BOS._BOS_value = this.dblTrendHigh;
                        //Set Current Trend as zero
                        this.intTrend = 0;
                   }
                   
               }
               
           }
           */
           
      }
}


void clsStructure::DrawLabel(string name, int xCord, int yCord, string text)
{
   //Print("Drawing watermark");
   name = this.strIdentifier + name;
   int WatermarkFontSize = 15;
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xCord);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yCord);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetString(0,  name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, WatermarkFontSize);
   ObjectSetDouble(0,  name, OBJPROP_ANGLE, 0.0);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 5);
   ObjectSetString(0,  name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, STRUC_LABEL_COL);
  
}


void clsStructure::CreateLabel()
{
   //this.DeleteLabel();
   string tag = "_structure";//this.strIdentifier+"_structure";
   //Alert("size is "+(string)ArraySize(this.intTrendArray));
   switch(this.intTrend)
   { 
       
       case 0:
           if(ArraySize(this.intTrendArray) > 1) this.DrawLabel(tag,550,30,"Break of Structure ! "+ " previous trend "+(string)this.intTrendArray[1]); 
           else {this.DrawLabel(tag,250,30,"Break of Structure !");}
           break;
       case 1:
           if(ArraySize(this.intTrendArray) > 1) this.DrawLabel(tag,550,30,"Bullish Structure !"+ " previous trend "+(string)this.intTrendArray[1]); 
           else {this.DrawLabel(tag,250,30,"Bullish Structure !");}
           break;
       case 2:
           if(ArraySize(this.intTrendArray) > 1) this.DrawLabel(tag,550,30,"Bearish Structure !"+ " previous trend "+(string)this.intTrendArray[1]); 
           else {this.DrawLabel(tag,250,30,"Bearish Structure !");}
           break;;
   }
   
}


void clsStructure::PlotBOS(int bar)
{
     if(this.intTrend==0)
     {
         color    colour_bos = this.BOS._prev_trend_type == 2 ? BOS_LINE_UP : BOS_LINE_DN;
         string   ob_name    = this.strIdentifier + " BOS";
         datetime bos_idxtime   = iTime(this.strSymbol,this.intPeriod,this.BOS._BOS_index);
         //Print("Start Index is ",this.BOSIndex);
         ObjectCreate(0,ob_name,OBJ_TREND,0,bos_idxtime,this.BOS._BOS_value,iTime(this.strSymbol,this.intPeriod,bar),this.BOS._BOS_value);
         //ObjectSet(ob_name, OBJPROP_RAY, false);  // now a point to point line not a ray
         ObjectSetInteger(0,ob_name,OBJPROP_COLOR,colour_bos);
         ObjectSetInteger(0,ob_name,OBJPROP_WIDTH,3);
     }
}

void clsStructure::PlotQML(int bar)
{
     if(this.intTrend==0)
     {
         this.FindBosQML();
         color    colour_qml = this.BOS._prev_trend_type == 2 ? BOS_LINE_UP : BOS_LINE_DN;
         string   ob_name    = this.strIdentifier + " QML";
         datetime bos_idxtime   = iTime(this.strSymbol,this.intPeriod,this.BOS._QML_index);
         //Print("Start Index is ",this.BOSIndex);
         ObjectCreate(0,ob_name,OBJ_TREND,0,bos_idxtime,this.BOS._QML,iTime(this.strSymbol,this.intPeriod,bar),this.BOS._QML);
         //ObjectSet(ob_name, OBJPROP_RAY, false);  // now a point to point line not a ray
         ObjectSetInteger(0,ob_name,OBJPROP_COLOR,colour_qml);
         ObjectSetInteger(0,ob_name,OBJPROP_WIDTH,3);
     }
}

int clsStructure::FindSuccesiveFractal(int type, int left_idx,int right_idx)
{
     //TYPE 1 : FIND LOW IN SUCCESSIVE HIGH
     //TYPE 2 : FIND HIGH IN SUCCESSIVE LOW
     int value = -1;
     if(type == 1)
     {
         for(int i = right_idx; i < left_idx; i++)
         {
             //self can also be a fractal low
             if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
             {
                 value = i;
                 break;
             }
         }
     }
     
     if(type == 2)
     {
         for(int i = right_idx; i < left_idx; i++)
         {
             if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
             {
                 value = i;
                 break;
             }
         }
     }
     
     return(value);
}


int clsStructure::FindBosBreakFractal(int type, int left_idx,int right_idx)
{
     //TYPE 1 : FIND LOW IN SUCCESSIVE HIGH
     //TYPE 2 : FIND HIGH IN SUCCESSIVE LOW
     int value = -1;
     if(type == 1)
     {
         for(int i = right_idx; i < left_idx; i++)
         {
             //self can also be a fractal low
             if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
             {
                 value = i;
                 break;
             }
         }
         if(value == -1) value = left_idx;
         
     }
     
     if(type == 2)
     {
         
         for(int i = right_idx; i < left_idx; i++)
         {
             if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
             {
                 value = i;
                 break;
             }
         }
         if(value == -1) value = left_idx;
          
     }
     
     return(value);
}

void clsStructure::FindBosQML()
{
    if(this.BOS._high > 0 && this.BOS._low > 0)
    {
       if(this.BOS._prev_trend_type == 1)
       {
            //QML is the first fractal high to the left of highest fractal
            for(int i = this.BOS._high_index + 1; i < this.BOS._high_index + LOOKBACK; i++)
            {
                  if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) > 0)
                  {
                      this.BOS._QML = iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
                      this.BOS._QML_index = i;
                      break;
                  }
            }
       }
       if(this.BOS._prev_trend_type == 2)
       {
            //QML is the first fractal high to the left of highest fractal
            for(int i = this.BOS._low_index + 1; i < this.BOS._low_index + LOOKBACK; i++)
            {
                  //Print("Looping i ",i);
                  if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) > 0)
                  {
                      this.BOS._QML = iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
                      this.BOS._QML_index = i;
                      break;
                  }
            }
       }
    }
}