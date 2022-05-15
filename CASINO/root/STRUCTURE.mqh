#include  "MASTER_INDI.mqh"
extern int LOOKBACK = 200;
extern color BOS_LINE_UP = clrLimeGreen;
extern color BOS_LINE_DN = clrRed;

class clsStructure : 
     public  clsMasterIndi
{
   public:
                      clsStructure(string strInputSymbol, int intInputTF);
                      ~clsStructure();
      void            Updater(datetime time, bool preloop=false);
      double          prev_low0;
      double          prev_low1;
      double          prev_mid0;
      double          prev_high0;
      double          prev_high1;
      int             prev_low0_index;
      int             prev_low1_index;
      int             prev_mid0_index;
      int             prev_high0_index;
      int             prev_high1_index;    
      double          prev_mid1;
      double          BOSLine;
      int             BOSIndex;
      bool            BOS;
      bool            _BOS;
      int             BOS_Type; // 1 break up, 2 break down
   protected:
      void            Oninit();
      void            ResetValue();
   
   private:
      string          strIdentifier;
      //STATIC VARIABLE TO UPDATE
      
      //INDICATOR VARIABLE TO BE RESETTED ON EACH RUN
      double          upper_lim;
      double          lower_lim;
      double          mid;
      
      
      int             trend;
      int             _trend;
      datetime        time0;
      datetime        time1;
      datetime        time00;
      datetime        timeb0;
      datetime        timeb1;
      datetime        to_begin;
      datetime        bos_time;
      //INDICATOR ARRAY
      double          bullish_up[];
      double          bullish_dn[];
      double          bearish_up[];
      double          bearish_dn[];
      //FUNCTION
      void            Find_Structure(int bar);
      void            CreateLabel(int bar);
      void            PlotBOS(int bar);
      void            PlotQML();
      void            DeleteLabel();
      void            FindBOSIndex(int bar);
      
   
};

clsStructure::clsStructure(string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
     {
        Print("Constructor at Child ",strInputSymbol);
        this.Oninit();
     }
 
clsStructure::~clsStructure()
{
     this.DeleteLabel();
     Comment("");
}

void clsStructure::Oninit(void)
{
    this.strIdentifier = "SNR"+(string)this.intPeriod;
    this.BOS = false;
    this._BOS = false;
    this.ResetValue(); 
}

void clsStructure::DeleteLabel(void)
{
   //Print("Prepare Delete");
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

void clsStructure::ResetValue(void)
{
    this.upper_lim = 0;
    this.lower_lim = 0;
    this.mid = 0;
    this.prev_high0 = 0;
    this.prev_low0 = 0;
    this.prev_mid0 = 0;
    this.prev_high1 = 0;
    this.prev_low1 = 0;
    this.prev_mid1 = 0;
    
    this.prev_low0_index = -1;
    this.prev_low1_index = -1;
    this.prev_mid0_index = -1;
    this.prev_high0_index= -1;
    this.prev_high1_index= -1; 
    
    this.trend = 0;
    this._trend = 0;
    this.time0 = 0;
    this.time1 = 0;
    this.time00 = 0;
    this.timeb0 = 0;
    this.timeb1 = 0;
    this.to_begin = 0;
    this.bos_time = 0;
}

void clsStructure::Updater(datetime time,bool preloop=false)
{
      /**
      This is a virtual function from parent, 
      - Meaning when code calling from Child, instead of running Parent Updater,
        child Updater shall be run
      **/
      //Print("Updating SnR");
      int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
      this.ResetValue();
      this.Find_Structure(latest_bar);
      this.CreateLabel(latest_bar);
      this.PlotBOS(latest_bar);
}


void clsStructure::Find_Structure(int bar)
{
      for(int i = bar + LOOKBACK; i > bar; i--)
      {
           datetime t0=iTime(this.strSymbol,this.intPeriod,i);
           double high=0;
           double low =0;
           //FIND FIRST FRACTAL HIGH LOW
           if(this.prev_high0==0 && this.prev_high1==0 && this.prev_low0==0 && this.prev_low1==0)
           {
           
                 int ck=0;
                 for(int k=1; k<=i; k++)
                 {
                     if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,k)>0)
                     {
                        this.prev_high0=iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,k);
                        this.prev_high0_index = k;
                     }
                     if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,k)>0)
                     {
                        this.prev_low0=iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,k);
                        this.prev_low0_index = k;
                     }
                     this._trend=0;
                     this.time00=iTime(this.strSymbol,this.intPeriod,k);
                 }
           }
           //FIND CURRENT FRACTAL
           high=iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i);
           low =iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i);
           
           if(iTime(this.strSymbol,this.intPeriod,i)<=this.time00){continue;}
           if(this.BOS && iTime(this.strSymbol,this.intPeriod,i)<=this.bos_time){continue;}
           
           //FIND BOS
           if(!this.BOS && this._trend==0 && iClose(this.strSymbol,this.intPeriod,i)<this.prev_low0  && this.prev_low0>0)
           {
               this.prev_low1  = this.prev_low0;
               this.prev_high1 = this.prev_high0;
               this.bos_time   = iTime(this.strSymbol,this.intPeriod,i);
               this.BOSLine    = this.prev_low0;
               //this.BOSIndex   = this.prev_low0_index;
               //Print("Finding boss 2 index of ",this.BOSIndex);
               this.BOS_Type   = 2;
               this.BOS=true;
           }
           if(!this.BOS && this._trend==1 && iClose(this.strSymbol,this.intPeriod,i)>this.prev_high1 && this.prev_high1>0)
           {
               this.prev_low0  = this.prev_low1;
               this.prev_high0 = this.prev_high1;
               this.bos_time   = iTime(this.strSymbol,this.intPeriod,i);
               this.BOSLine    = this.prev_high1;
               //this.BOSIndex   = this.prev_high0_index;
               //Print("Finding boss 1 index of ",this.BOSIndex);
               this.BOS_Type   = 1;
               this.BOS=true;
           }
           
           //RE-VERIFICATION
           if(this._trend==0 || this.BOS)
           {
              if(high>0 && (high > this.prev_high0 || this.prev_high0==0))
              {
                  if(!this.BOS)
                  {
                     this.prev_high1=0;
                     this.prev_low1=0;
                  }
                  this.prev_high0 = high;
                  this.time0 = iTime(this.strSymbol,this.intPeriod,i);
                  if(!this.BOS || this._trend==2)
                  {
                     for(int j=i; j<= i + LOOKBACK; j++)
                     {
                          low=iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,j);
                          if(low>0)
                          {
                             this.prev_low0=low;
                             this.time1=iTime(this.strSymbol,this.intPeriod,j);
                             break;
                          }
                     }
                  }
                  if(this.BOS && (this._trend==0 || this._trend==2))
                  {
                     this._trend=0;
                     this.BOS=false;
                  }
                  if(this.BOS && this._trend==1)
                  {
                     this._trend=2;
                     //prev_low1=prev_low0;
                     this.prev_high1=this.prev_high0;
                  }
              }
           }
           
           if(this._trend==1 || this.BOS)
           {
               if(low>0 && (low < this.prev_low1 || this.prev_low1==0))
                 {
                     if(!this.BOS)
                     {
                        this.prev_high0=0;
                        this.prev_low0=0;
                     }
                     this.prev_low1 = low;
                     time1=iTime(this.strSymbol,this.intPeriod,i);
                     if(!this.BOS || this._trend==2)
                     {
                          for(int j=i; j<= i + LOOKBACK; j++)
                          {
                             high=iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,j);
                             if(high>0  && (high < this.prev_high1 || this.prev_high1==0))
                             {
                                 this.prev_high1=high;
                                 this.time0=iTime(this.strSymbol,this.intPeriod,j);
                                 break;
                             }
                          }
                     }
                     if(this.BOS && (this._trend==1 || this._trend==2))
                     {
                        this._trend=1;
                        this.BOS=false;
                     }
                     if(this.BOS && this._trend==0)
                     {
                        this._trend=2;
                        this.prev_low0=this.prev_low1;
                        //prev_high0=prev_high1;
                     }
                 }
           }
            
           
      }
}

void clsStructure::CreateLabel(int bar)
{
     Comment("");
     if(this._trend==0)
     {
        if(!this.BOS)
        {
            Comment("Trend is bullish!");
            int g=iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,iBarShift(this.strSymbol,this.intPeriod,this.time0)-1,bar+1);
            double h0=this.prev_high0;
            if(iHigh(this.strSymbol,this.intPeriod,g)>h0)
            {
               h0=iHigh(this.strSymbol,this.intPeriod,g);
               //SetFibo("Fibo_",iTime(_Symbol,PERIOD_CURRENT,g),h0,time1,prev_low0,clrBlue,1,clrBlue);
            }
            
            else
            {
            //   SetFibo("Fibo_",time0,h0,time1,prev_low0,clrBlue,1,clrBlue);
            //bullish_up[MathMax(1,iBarShift(_Symbol,tf,time0))]=prev_high0;
            //bullish_dn[MathMax(1,iBarShift(_Symbol,tf,time1))]=prev_low0;
            this._BOS=false;
            }
        }
   }
   if(_trend==1)
   {
      if(!this.BOS)
      {
         Comment("Trend is bearish!");
         int g=iLowest(this.strSymbol,this.intPeriod,MODE_LOW,iBarShift(this.strSymbol,this.intPeriod,this.time1)-1,bar+1);
         double l0=this.prev_low1;
         if(iLow(this.strSymbol,this.intPeriod,g)<l0)
         {
            l0=iLow(this.strSymbol,this.intPeriod,g);
            //SetFibo("Fibo_",iTime(_Symbol,PERIOD_CURRENT,g),l0,time0,prev_high1,clrRed,1,clrRed);
         }
         else
         {
         //   SetFibo("Fibo_",time1,l0,time0,prev_high1,clrRed,1,clrRed);
         //bearish_up[MathMax(1,iBarShift(_Symbol,tf,time0))]=prev_high1;
         //bearish_dn[MathMax(1,iBarShift(_Symbol,tf,time1))]=prev_low1;
         this._BOS=false;
         }
      }
   }
   if(BOS)
   {
      Comment("Break of structure");
      //SetFibo("Fibo_",time0,prev_high0,time1,prev_low0,clrYellow,1,clrYellow);
      //bullish_up[MathMax(1,iBarShift(_Symbol,tf,time0))]=prev_high0;
      //bullish_dn[MathMax(1,iBarShift(_Symbol,tf,time1))]=prev_low0;
      //bearish_up[MathMax(1,iBarShift(_Symbol,tf,time0))]=prev_high1;
      //bearish_dn[MathMax(1,iBarShift(_Symbol,tf,time1))]=prev_low1;
      this._BOS=true;
   }
}

void clsStructure::FindBOSIndex(int bar)
{
   if(this.BOS_Type == 1)
   {
       for(int i = bar; i < bar +LOOKBACK; i++)
       {
           if(iFractals(this.strSymbol,this.intPeriod,MODE_UPPER,i) == this.BOSLine)
           {
                this.BOSIndex = i;
                break;
           }
       }
   }
   else
   {
      if(this.BOS_Type == 2)
      {
          for(int i = bar; i < bar +LOOKBACK; i++)
          {
              if(iFractals(this.strSymbol,this.intPeriod,MODE_LOWER,i) == this.BOSLine)
              {
                   this.BOSIndex = i;
                   break;
              }
          }
      }
   }
}

void clsStructure::PlotBOS(int bar)
{
     if(this.BOS)
     {
         this.DeleteLabel();
         this.FindBOSIndex(bar);
         color    colour_bos = this.BOS_Type == 1 ? BOS_LINE_UP : BOS_LINE_DN;
         string   ob_name    = this.strIdentifier + " BOS";
         datetime bos_idxtime   = iTime(this.strSymbol,this.intPeriod,this.BOSIndex);
         Print("Start Index is ",this.BOSIndex);
         ObjectCreate(0,ob_name,OBJ_TREND,0,bos_idxtime,this.BOSLine,iTime(this.strSymbol,this.intPeriod,bar),this.BOSLine);
         //ObjectSet(ob_name, OBJPROP_RAY, false);  // now a point to point line not a ray
         ObjectSetInteger(0,ob_name,OBJPROP_COLOR,colour_bos);
         ObjectSetInteger(0,ob_name,OBJPROP_WIDTH,3);
     }
}