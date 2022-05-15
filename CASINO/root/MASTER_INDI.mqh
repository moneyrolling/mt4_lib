//SHORT NOTE
/**
VIRTUAL vs OVERRIDE
1. OVERRIDE
- if we declare a same name function as parent in child class
- when we called from child class, it will just run from the child class 
2. VIRTUAL
- if we declare a same name as Parent but different function
- We need to call that Function from parent to run the child function
- so we need define that function as "virtual" in parent

 Child Constructor :
   - Parent Costructor -> Child Constructor -> once child construct -> only Virtual function take place
**/
enum period  // enumeration of named constants
  {
   //CURRENT = 0,
   M1  = PERIOD_M1,  
   M5  = PERIOD_M5,     
   M15 = PERIOD_M15,  
   M30 = PERIOD_M30,  
   H1  = PERIOD_H1,
   H4  = PERIOD_H4,
   D1  = PERIOD_D1,
   W1  = PERIOD_W1,
   MN1 = PERIOD_MN1  
  };

enum MA_MODE
{
     ARRAY_SMA,
     ARRAY_EMA     
};

class clsMasterIndi
{
    public:
       clsMasterIndi(string strInputSymbol, int intInputTF);
       ~clsMasterIndi();
       virtual void    Updater(datetime time, bool preloop=false);
       bool     blNewBar(bool use_first=true);
       int      intPeriod;
       string   strSymbol;
       double   dblMAOnArray(double &values[], int ma_period, int start_idx, MA_MODE mode=ARRAY_SMA);
       //ARRAY LIST
       double   Opens[];
       double   Highs[];
       double   Lows[];
       double   Closes[];
       datetime Times[];
       void     StoreArray(double value, double &Arrvalue[], int max_size=0, bool save_duplicate=false);
       void     StoreArray(int value, int &Arrvalue[], int max_size=0, bool save_duplicate=false);
       void     StoreArray(datetime value, datetime &Arrvalue[], int max_size=0, bool save_duplicate=false);
    protected:
       //function to inherit
       int      intMaxStore;
       void     Oninit();
       void     Preloop();
       void     StoreIndi(double value, double &values[]);
       
       //ADDITIONAL, KIV for later
       bool     blChartEvent();
       void     ReloadChart();
       int      intHighestIdx(double &values[], int count=0, int start_idx=0);
       int      intLowestIdx(double &values[],  int count=0, int start_idx=0);
       int      intBarByDate(datetime &dates[], datetime find_date);
       int      save_bar;
       datetime save_time;
       //datetime save_time;
};

clsMasterIndi::clsMasterIndi(string strInputSymbol, int intInputTF)
{   //Print("Constructor at Mother");
    this.strSymbol = strInputSymbol;
    this.intPeriod = intInputTF;
    this.Oninit(); 
}

clsMasterIndi::~clsMasterIndi(){}

void clsMasterIndi::Oninit(void)
{
    //Once we create new child class from mother class, this function will be load first
    //some universal Init function to be addon later
    //Print("Oninit on Mother");
    
}

void clsMasterIndi::Preloop(void)
{
    //CAN BE REUSED/CALLED FROM CHILD
    //ONLY USEFUL IN EA MODE TO PRELOOP AND STORE SOME DATA PRIOR EACH RUN
    
    for(int i = this.intMaxStore; i > 2; i--)   //IMPORTANT : We skip 1 here as later we will call them in updater, we use confirmed close candle only, meaning not taking the signal candle 0
    {
        datetime time = iTime(this.strSymbol,this.intPeriod,i);
        this.Updater(time);
    }
    
    //Print("Loop on Mother");
    
}
void clsMasterIndi::Updater(datetime time, bool preloop=false)
{
    /**
   This is a virtual function at Parent, 
   - Meaning when code calling from Child, instead of running Parent Updater,
     child Updater shall be run
   **/
   //Print("Updater running on Mother");
}


bool clsMasterIndi::blNewBar(bool use_first=true)
{
    //static int save_bar;
    static double save_close;
    datetime current_time = iTime(this.strSymbol,this.intPeriod,1);//TimeCurrent();
    int      cur_bar = (int)(current_time/(this.intPeriod*60));
    
    //Print(this.strSymbol+(string)this.intPeriod+" Latest Time is ",current_time);
    //Print("Timeframe value is ",this.intPeriod);
    if(save_bar == 0)
    {
         if(use_first)
         {
              //Print((string)this.intPeriod+" I save A");
              save_bar = cur_bar;
              save_close = iClose(this.strSymbol,this.intPeriod,1);
              //Print((string)this.intPeriod+" A Latest Bar Close is ",save_close);
              return(true);
         }
    }
    else
    {
         if(save_bar != cur_bar && cur_bar > save_bar)
         {
              //Print((string)this.intPeriod+" Current Bar is "+cur_bar);
              //Print((string)this.intPeriod+" Save Bar is "+save_bar);
              //Print((string)this.intPeriod+" I save B");
              save_bar = cur_bar;
              save_close = iClose(this.strSymbol,this.intPeriod,1);
              //Print((string)this.intPeriod+" B Latest Bar Close is ",save_close);
              return(true);
         }
    }
    return(false);
}


int clsMasterIndi::intHighestIdx(double &values[], int count=0, int start_idx=0)
{
    if(count == 0) count = ArraySize(values);
    //Print("Count is ",count);
    //Print("Start Idx is ",start_idx);
    if(count > ArraySize(values)) 
    {
        Alert("Count Index exit array size, Exiting!");
        ExpertRemove();
        return(-1);
    }
    double highest = DBL_MIN;
    int    highest_idx = start_idx;
    int    end_idx = start_idx + count >= ArraySize(Highs) ? ArraySize(Highs) : start_idx + count;
    for(int i = start_idx; i < end_idx; i++)
    {
         //Print("Current Looping i is ",i);
         double cur_high = values[i];
         if(cur_high > highest)
         {
             highest     = cur_high;
             highest_idx = i;
         }
    }
    return(highest_idx);
}

int clsMasterIndi::intLowestIdx(double &values[], int count=0, int start_idx=0)
{
    if(count == 0) count = ArraySize(values);
    if(count > ArraySize(values)) 
    {
        Alert("Count Index exit array size, Exiting!");
        ExpertRemove();
        return(-1);
    }
    double lowest = DBL_MAX;
    int    lowest_idx = start_idx;
    int    end_idx = start_idx + count >= ArraySize(Highs) ? ArraySize(Highs) : start_idx + count;
    for(int i = start_idx; i < end_idx; i++)
    {
         double cur_low = values[i];
         if(cur_low < lowest)
         {
             lowest     = cur_low;
             lowest_idx = i;
         }
    }
    return(lowest_idx);
}

int clsMasterIndi::intBarByDate(datetime &dates[], datetime find_date)
{
    for(int i = 0; i < ArraySize(dates); i++)
    {
        if(find_date == dates[i])
        {
            return(i);
        }
    }
    return(-1);
}

void clsMasterIndi::StoreIndi(double value, double &values[])
{  
    //Print("Storing ",value);
    ArrayCopy(values,values,1,0,this.intMaxStore);
    values[0] = value;
    //Print("size is ",ArraySize(values));
    //Print("Latest Store Value is ",values[0]);
}

void clsMasterIndi::StoreArray(datetime value, datetime &Arrvalue[], int max_size=0, bool save_duplicate=false)
{
    if(!save_duplicate)
    {
       if(max_size == 0)
       {
            //dynamic array
            if(ArraySize(Arrvalue) >0)
            {
                 if(Arrvalue[0] != value)
                 {
                      ArrayCopy(Arrvalue,Arrvalue,1,0);
                      Arrvalue[0] = value;
                 }
            }
            else
            {
                //first data
                ArrayResize(Arrvalue,1);
                Arrvalue[0] = value;
            }
       }
       else
       {
            //fixed size array
            int size = ArraySize(Arrvalue);
            if(size > 0)
            {
                if(size >= max_size)
                {
                   if(Arrvalue[0] != value)
                   {
                      ArrayCopy(Arrvalue,Arrvalue,1,0,max_size-1);
                      Arrvalue[0] = value;
                   }
                }
                else
                {
                   if(Arrvalue[0] != value)
                   {
                      ArrayCopy(Arrvalue,Arrvalue,1,0);
                      Arrvalue[0] = value;
                   }
                }
            }
            else
            {
                   //first data
                   ArrayResize(Arrvalue,1);
                   Arrvalue[0] = value;
            }
       }
    }
    else
    {
       if(max_size == 0)
       {
            //dynamic array
            if(ArraySize(Arrvalue) >0)
            {
                  ArrayCopy(Arrvalue,Arrvalue,1,0);
                  Arrvalue[0] = value;
            }
            else
            {
                //first data
                ArrayResize(Arrvalue,1);
                Arrvalue[0] = value;
            }
       }
       else
       {
            int size = ArraySize(Arrvalue);
            if(size > 0)
            {
                if(size >= max_size)
                {
                   ArrayCopy(Arrvalue,Arrvalue,1,0,max_size-1);
                   Arrvalue[0] = value;
                }
                else
                {
                   ArrayCopy(Arrvalue,Arrvalue,1,0);
                   Arrvalue[0] = value;
                   
                }
            }
            else
            {
                   //first data
                   ArrayResize(Arrvalue,1);
                   Arrvalue[0] = value;
            }
       }
    }
}

void clsMasterIndi::StoreArray(double value, double &Arrvalue[], int max_size=0, bool save_duplicate=false)
{
    if(!save_duplicate)
    {
       if(max_size == 0)
       {
            //dynamic array
            if(ArraySize(Arrvalue) >0)
            {
                 if(Arrvalue[0] != value)
                 {
                      ArrayCopy(Arrvalue,Arrvalue,1,0);
                      Arrvalue[0] = value;
                 }
            }
            else
            {
                //first data
                ArrayResize(Arrvalue,1);
                Arrvalue[0] = value;
            }
       }
       else
       {
            //fixed size array
            int size = ArraySize(Arrvalue);
            if(size > 0)
            {
                if(size >= max_size)
                {
                   if(Arrvalue[0] != value)
                   {
                      ArrayCopy(Arrvalue,Arrvalue,1,0,max_size-1);
                      Arrvalue[0] = value;
                   }
                }
                else
                {
                   if(Arrvalue[0] != value)
                   {
                      ArrayCopy(Arrvalue,Arrvalue,1,0);
                      Arrvalue[0] = value;
                   }
                }
            }
            else
            {
                   //first data
                   ArrayResize(Arrvalue,1);
                   Arrvalue[0] = value;
            }
       }
    }
    else
    {
       if(max_size == 0)
       {
            //dynamic array
            if(ArraySize(Arrvalue) >0)
            {
                  ArrayCopy(Arrvalue,Arrvalue,1,0);
                  Arrvalue[0] = value;
            }
            else
            {
                //first data
                ArrayResize(Arrvalue,1);
                Arrvalue[0] = value;
            }
       }
       else
       {
            int size = ArraySize(Arrvalue);
            if(size > 0)
            {
                if(size >= max_size)
                {
                   ArrayCopy(Arrvalue,Arrvalue,1,0,max_size-1);
                   Arrvalue[0] = value;
                }
                else
                {
                   ArrayCopy(Arrvalue,Arrvalue,1,0);
                   Arrvalue[0] = value;
                   
                }
            }
            else
            {
                   //first data
                   ArrayResize(Arrvalue,1);
                   Arrvalue[0] = value;
            }
       }
    }
}


void clsMasterIndi::StoreArray(int value, int &Arrvalue[], int max_size=0, bool save_duplicate=false)
{
    if(!save_duplicate)
    {
       if(max_size == 0)
       {
            //dynamic array
            if(ArraySize(Arrvalue) >0)
            {
                 if(Arrvalue[0] != value)
                 {
                      ArrayCopy(Arrvalue,Arrvalue,1,0);
                      Arrvalue[0] = value;
                 }
            }
            else
            {
                //first data
                ArrayResize(Arrvalue,1);
                Arrvalue[0] = value;
            }
       }
       else
       {
            //fixed size array
            int size = ArraySize(Arrvalue);
            if(size > 0)
            {
                if(size >= max_size)
                {
                   if(Arrvalue[0] != value)
                   {
                      ArrayCopy(Arrvalue,Arrvalue,1,0,max_size-1);
                      Arrvalue[0] = value;
                   }
                }
                else
                {
                   if(Arrvalue[0] != value)
                   {
                      ArrayCopy(Arrvalue,Arrvalue,1,0);
                      Arrvalue[0] = value;
                   }
                }
            }
            else
            {
                   //first data
                   ArrayResize(Arrvalue,1);
                   Arrvalue[0] = value;
            }
       }
    }
    else
    {
       if(max_size == 0)
       {
            //dynamic array
            if(ArraySize(Arrvalue) >0)
            {
                  ArrayCopy(Arrvalue,Arrvalue,1,0);
                  Arrvalue[0] = value;
            }
            else
            {
                //first data
                ArrayResize(Arrvalue,1);
                Arrvalue[0] = value;
            }
       }
       else
       {
            int size = ArraySize(Arrvalue);
            if(size > 0)
            {
                if(size >= max_size)
                {
                   ArrayCopy(Arrvalue,Arrvalue,1,0,max_size-1);
                   Arrvalue[0] = value;
                }
                else
                {
                   ArrayCopy(Arrvalue,Arrvalue,1,0);
                   Arrvalue[0] = value;
                   
                }
            }
            else
            {
                   //first data
                   ArrayResize(Arrvalue,1);
                   Arrvalue[0] = value;
            }
       }
    }
}


double clsMasterIndi::dblMAOnArray(double &values[], int ma_period, int start_idx, MA_MODE mode=ARRAY_SMA)
{
    // for sake of simplicity we use SMA
    if(ArraySize(values) < start_idx + ma_period || ma_period == 0) 
    {
        //Print("OverLoop");
        //Print("Size of value is ",ArraySize(values));
        //Print("Start idx is ",start_idx);
        return(0);
    }
    double sum_value = 0;
    double mean      = 0;
    if(mode == ARRAY_SMA)
    {
       for(int i = start_idx; i < start_idx + ma_period; i++)
       {
           sum_value += values[i];
       }
       mean = sum_value/ma_period;
    }
    if(mode == ARRAY_EMA)
    {
       double first_ema = 0;
       double first_sum = 0;
       for(int i = ArraySize(values) - 1; i >  ArraySize(values) - 1 - ma_period; i--)
       {
            first_sum += values[i];
       }
       first_ema = first_sum/ma_period;
       
       //we need to get from whole array
       double prev_ema = 0;
       for(int i = ArraySize(values) - 1 - ma_period; i >= 0; i--)
       {
            //get the multiplier first
            prev_ema = prev_ema == 0 ? first_ema : prev_ema;
            
            double k       = 2/(double)(ma_period+1);
            double ema_cur = k * (values[i] - prev_ema) + prev_ema;
            if(NormalizeDouble(values[0],2) == 1824.89)
            {
                Print("Found EMA at index ",i, " with value of ",values[i]);
                Print("First ema is ",first_ema);
                Print("EMA current is ",ema_cur);
            }
            if(i == start_idx)
            {
               mean = ema_cur;
               break;
            }
            prev_ema = ema_cur;
       }
       //mean = first_ema;
    }
    return(mean); 
}