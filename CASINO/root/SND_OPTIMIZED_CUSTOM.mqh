//+------------------------------------------------------------------+
//|                                                SND_OPTIMIZED.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
extern string _tmp3_ = "===== SNR SETTINGS =====";
bool FreshZoneOnly = false;         // Toggling Session : Use freshzone
bool ToggleSession = false;
extern bool DrawSNDLevel = true;
extern bool DrawNumberLine = true;
input int CandleLimit = 300;             // Candle Limit
input double Min_Gap = 10; 
input color SND1_ColorSupport = clrBlue;   // SND TF 1 Support Color
input color SND1_ColorResistance = clrRed; // SND TF 1 Resistance Color
input int   Round_Number = 100;
input color Round_Number_Line_Color    = clrWhite;
#include  "MASTER_INDI.mqh"
#include "MASTER_CONFIG.mqh"
#include "OBJECT_FUNC.mqh"
int max_store       = 5000;

enum   SND_MODE  
{
    NORMAL_MODE  = 1,
    FRESH_MODE   = 2
};

//FLOW : FIND ENGULFING CANDLE=> FIND HIGH AND LOW => STORE THEM INTO LVL => REMOVE INTERSECTION => ADD INTO STORAGE

struct CLevel
{
   double            highPrice;
   double            lowPrice;
   datetime          startDate;
   bool              isActive;
   bool              isFresh;
   bool              isBreak;
   bool              isInterSected;
   bool              isInsider;
   bool              isNearGap;
   string            type;
   int               SNDBaseDist; //1 is base 1 candle, 2 is base 2 candle
   int               HideIdx;
   double            RoundNumber[];
   
   CLevel() : highPrice(0), lowPrice(0), startDate(0), isActive(false), isFresh(true), isBreak(false), isInterSected(false), isInsider(false), type(""), SNDBaseDist(0), HideIdx(-1) {}; 
};


class clsSND : 
     public  clsMasterIndi
{
   public:
                      clsSND(string strInputSymbol, int intInputTF);
                      ~clsSND();
      CLevel          LevelList[];
                      //CLevel levelList[];
      void            Updater(datetime time, bool preloop=false, bool check_direction=true);
      void            DrawLevel();
      void            FindNearestLevel(int cur_bar);
      datetime        res_start_time;
      datetime        sup_start_time;
      double          res_up;
      double          res_dn;
      double          sup_up;
      double          sup_dn;
      datetime        res_start_time_fresh;
      datetime        sup_start_time_fresh;
      double          res_up_fresh;
      double          res_dn_fresh;
      double          sup_up_fresh;
      double          sup_dn_fresh;
      color           res_color;
      color           sup_color;
      CLevel          latest_res_lvl;
      CLevel          latest_sup_lvl;
      CLevel          latest_fresh_res_lvl;
      CLevel          latest_fresh_sup_lvl;
      //find last res/sup
      void            FindLastResSup();
      int             intMaxStoreCount;
      double          res_up_list[];
      double          res_dn_list[];
      double          sup_up_list[];
      double          sup_dn_list[];
      double          res_up_prev;
      double          res_dn_prev;
      double          sup_up_prev;
      double          sup_dn_prev;
      int             res_bar;
      int             sup_bar;
      int             res_bar_fresh;
      int             sup_bar_fresh;
      int             intLastSupIdx;
      int             intLastResIdx;
      int             intLastFreshSupIdx;
      int             intLastFreshResIdx;
      int             intCurrentDirection(int cur_bar, SND_MODE mode = 1);
      int             intGetEngulfingCandleSignal1(int bar);
      int             intGetEngulfingCandleSignal2(int bar);
      bool            blIsGreenCandle(int bar);
      void            DrawLabel(string name, int xCord, int yCord, string text);
      bool            blDrawMode;
      bool            blCommentMode;
      string          strToggleName;
      bool            blFreshMode;
      bool            blEAMode;
      int             intFinalDirection;
      void            FinalDirectionCheck();
      int             intGetEngulfingTrend();
      int             intEngulfingTrend;
      double          dblEngulfingLow;
      double          dblEngulfingHigh;
   protected:
      void            Oninit();
      void            LoopCustomOHLC();
      
      
   private:
      //INDIVIDUALIZED PARAMETERS FOR DIFFERENT INDICATOR
      
      void            StoreOHLC(int bar, bool initialize=false);
      //bool            blIsGreenCandle(int bar);
      //int             intGetEngulfingCandleSignal1(int bar);
      //int             intGetEngulfingCandleSignal2(int bar);
      void            RefreshOnNewBar(int bar);
      void            FindSnR(int bar);
      void            UpdateSnR(int bar);
      void            RemoveIntersectingLevels(CLevel& addedLevel);
      void            AddToLevelList(CLevel& level);
      void            UpdateLevels(int bar);    // Removes/Flips levels when they are tested/broken
      void            RecoverInactive(int type, CLevel& level, double break_price);
      void            Reactive(int bar);
      void            ReactiveRemoveMinGap(CLevel& reactived_level, int arr_idx);
      void            RemoveInsiderPostReactive();
      void            DrawRoundNumberLine(CLevel &level);
      void            DrawRectangle(double price1, datetime time1, double price2, datetime time2, string type="");
      void            DeleteLevel();
      void            PlotZone(int type);
      void            CheckFreshLevel(int bar);
      void            CreateToggle(); //toggle to switch on and off fresh zone
      void            FindRoundNumber();
      string          strIdentifier;
      string          strSNRType;  //OUTPUT AS SUPPORT / RESISTANCE
      int             intEngulfedCandleDist;  
      int             intResCount;
      int             intSupCount; 
      int             intResFreshCount;
      int             intSupFreshCount; 
      void            StoreSnrLevel();
      CLevel          FreshLevelList[];   
      void            CopyCLevel(CLevel &source[], CLevel &destination[]);
      
   
};


clsSND::clsSND(string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
     {
        Print("Constructor at Child ",strInputSymbol);
        this.Oninit();
     }
 
clsSND::~clsSND()
{
     this.DeleteLevel();
     Comment("");
     for (int i=ObjectsTotal()-1; i >= 0; i--) 
     {
         string obj_name = ObjectName(i); 
         if(StringFind(obj_name,obj_name)>=0)
         {
             //Print("Deleting ",obj_name);
             ObjectDelete(0,obj_name);
         }
     }
   
}

void clsSND::Oninit(void)
{
     
     //clsMasterIndi::Oninit(); //NO NEED THIS CODE, as once parent construct, it will loop from parent
     this.intMaxStore = max_store; //maximum number of candles to loop
     this.strIdentifier = (string)this.intPeriod+this.strSymbol+"SNR";
     this.intLastSupIdx = -1;
     this.intLastResIdx = -1;
     this.intLastFreshSupIdx = -1;
     this.intLastFreshResIdx = -1;
     this.blDrawMode = true;
     this.blCommentMode = true;
     this.intMaxStoreCount = 400;
     if(!this.blEAMode) this.sup_color = SND1_ColorSupport;
     if(!this.blEAMode) this.res_color = SND1_ColorResistance;  
     //this.StoreOHLC(1,true);  
     Alert("Post Init Array Size in Period ",this.intPeriod, " Is ",ArraySize(this.Opens)); 
}

void clsSND::StoreOHLC(int bar, bool initialize=false)
{
     if(initialize)
     {
         Alert("Initial Array Size in Period ",this.intPeriod, " Is ",ArraySize(this.Closes));
         for(int i = bar+CandleLimit+2; i >= bar ; i--)
         {
             double open   = iOpen(this.strSymbol,this.intPeriod,i);
             double high   = iHigh(this.strSymbol,this.intPeriod,i);
             double low    = iLow(this.strSymbol,this.intPeriod,i);
             double close  = iClose(this.strSymbol,this.intPeriod,i);
             datetime time = iTime(this.strSymbol,this.intPeriod,i);
             this.StoreArray(open,this.Opens,CandleLimit+2,true);
             this.StoreArray(high,this.Highs,CandleLimit+2,true);
             this.StoreArray(low,this.Lows,CandleLimit+2,true);
             this.StoreArray(close,this.Closes,CandleLimit+2,true);
             this.StoreArray(time,this.Times,CandleLimit+2,true);
         }
     }
     else
     {
          double open   = iOpen(this.strSymbol,this.intPeriod,bar);
          double high   = iHigh(this.strSymbol,this.intPeriod,bar);
          double low    = iLow(this.strSymbol,this.intPeriod,bar);
          double close  = iClose(this.strSymbol,this.intPeriod,bar);
          datetime time = iTime(this.strSymbol,this.intPeriod,bar);
          this.StoreArray(open,this.Opens,CandleLimit+2,true);
          this.StoreArray(high,this.Highs,CandleLimit+2,true);
          this.StoreArray(low,this.Lows,CandleLimit+2,true);
          this.StoreArray(close,this.Closes,CandleLimit+2,true);
          this.StoreArray(time,this.Times,CandleLimit+2,true);
     }
}

int clsSND::intHighestIdx(double &values[], int count=0, int start_idx=0)
{
    if(count == 0) count = ArraySize(values);
    Print("Count is ",count);
    Print("Start Idx is ",start_idx);
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

int clsSND::intLowestIdx(double &values[], int count=0, int start_idx=0)
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

int clsSND::intBarByDate(datetime &dates[], datetime find_date)
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

void clsSND::RefreshOnNewBar(int bar)  //to reset on each new bar
{
     ArrayFree(this.LevelList);
     datetime time_start = GetTickCount();
     
     //Alert("Stored Size Array in Period ",this.intPeriod, " Is ",ArraySize(this.Closes));
     //for(int i = bar+CandleLimit; i >= bar ; i--)
     for(int i =ArraySize(Highs)-3; i >= 0; i--)
     {
         //Alert("Current Running I is ",i);
         this.UpdateLevels(i); //Flip when break
         //Alert("Close in Period ",this.intPeriod, " with index ",i," Is ",this.Closes[i]);
         //Alert("Close in Period ",this.intPeriod, " with index + 1 ",i," Is ",this.Closes[i+1]);
         this.FindSnR(i);
         this.UpdateSnR(i);
         
     }
     //Alert("Size of Level List in TimeFrame ",this.intPeriod," is ",ArraySize(this.LevelList));
     datetime time_end   = GetTickCount();
     //Print("Time Elapsed Per Cycle for TimeFrame ",this.intPeriod," is ",(double)(time_end-time_start));
}

void clsSND::LoopCustomOHLC()
{
    ArrayFree(Opens);
    ArrayResize(Opens,CandleLimit);
    ArrayFree(Highs);
    ArrayResize(Highs,CandleLimit);
    ArrayFree(Lows);
    ArrayResize(Lows,CandleLimit);
    ArrayFree(Closes);
    ArrayResize(Closes,CandleLimit);
    ArrayFree(Times);
    ArrayResize(Times,CandleLimit);
    for(int i = ArraySize(Highs) - 1; i >= 0; i--)
    {
         //Alert("Looping i of ",i);
         Opens[i]  = iOpen(strSymbol,intPeriod,i);
         Highs[i]  = iHigh(strSymbol,intPeriod,i);
         Lows[i]   = iLow (strSymbol,intPeriod,i);
         Closes[i] = iClose(strSymbol,intPeriod,i);
         Times[i]  = iTime(strSymbol,intPeriod,i);
    }
}


void clsSND::Updater(datetime time,bool preloop=false, bool check_direction=true)
{
      /**
      This is a virtual function from parent, 
      - Meaning when code calling from Child, instead of running Parent Updater,
        child Updater shall be run
      **/
      //Print("Updating SnR");
      int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
      LoopCustomOHLC();
      if(latest_bar > ArraySize(Highs) - 2) return;
      //Alert("Updating latest bar of ",latest_bar);
      
      //if(latest_bar == 0)
      //{
         //Print(this.intPeriod," New Loop Triggered");
         //this.StoreOHLC(latest_bar+1); 
         //Alert("Open Array Size in Period ",this.intPeriod, " Is ",ArraySize(this.Opens));
         //Alert("Latest Open Price in Period ",this.intPeriod, " Is ",this.Opens[0]); 
         //Alert("Latest Close Price in Period ",this.intPeriod, " Is ",this.Closes[0]); 
         //Alert("PRE SAVE LEVEL SIZE IS ",ArraySize(this.LevelList));
         this.RefreshOnNewBar(latest_bar);
         //this.UpdateLevels(latest_bar);
         //this.FindSnR(latest_bar);
         //this.UpdateSnR(latest_bar);
         //PLOT LATEST SNR VALUE
         this.FindNearestLevel(latest_bar);
         this.Reactive(latest_bar);
         this.RemoveInsiderPostReactive();
         this.FindRoundNumber();
         //this.UpdateLevels(latest_bar);
         this.FindNearestLevel(latest_bar);
         this.FindLastResSup();
         this.CheckFreshLevel(latest_bar);
         //this.UpdateLevels(latest_bar);
         if(ChartSymbol() == this.strSymbol) this.DrawLevel();
         if(check_direction)
         {
            /*
            if(!this.blFreshMode) {this.intCurrentDirection(0,1);} //NORMAL SND DIRECTION
            else{this.intCurrentDirection(0,2);} //FRESH  SND DIRECTION
            */
            if(!this.blFreshMode) {this.intCurrentDirection(latest_bar,1);} //NORMAL SND DIRECTION
            else{this.intCurrentDirection(latest_bar,2);} //FRESH  SND DIRECTION
            
         }
         if(ChartSymbol() == this.strSymbol && ChartPeriod() == this.intPeriod)
         {
            if(this.blCommentMode) this.DrawLabel("Watermark", 10, 20, "EUPORIAFX MARKETS PERFORMANCE");
            if(this.blCommentMode) this.CreateToggle();
         }
         //Alert("POST SAVE LEVEL SIZE IS ",ArraySize(this.LevelList));
         
      //}
}



void clsSND::CreateToggle(void)
{
      //Alert("SND ",this.intPeriod," created toggle ");
      this.strToggleName = StringConcatenate(this.strIdentifier," toggle_button");
      Create_Button(this.strToggleName,"TOGGLE SND",150,130,10 + 150,530 ,clrGray,clrBlack);
}


void clsSND::Reactive(int bar)
{
     for (int i = ArraySize(this.LevelList)-1; i >= 0; i--)
     {
           if(this.LevelList[i].isActive == false &&
              this.LevelList[i].isBreak  == false &&
              this.LevelList[i].isInterSected == true &&
              this.LevelList[i].isInsider == false
             )
           {
                if(this.LevelList[i].type == "Support")
                {
                   if(this.LevelList[i].lowPrice < iLow(this.strSymbol,this.intPeriod,bar) && //this.Lows[bar] && //
                      this.LevelList[i].lowPrice > this.sup_up //&&
                      //thi
                     )
                   {
                         //int bar_shift = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                         //Print("Support start with bar ",bar_shift," break");
                         //Print("Support start with bar ",bar_shift," low price is ",this.LevelList[i].lowPrice);
                         this.LevelList[i].isActive = true;
                         //this.ReactiveRemoveMinGap(LevelList[i],i);
                         break;
                   }
                }
           }
     }
     
     for (int i = ArraySize(this.LevelList)-1; i >= 0; i--)
     {
           if(this.LevelList[i].isActive == false &&
              this.LevelList[i].isBreak  == false &&
              this.LevelList[i].isInterSected == true &&
              this.LevelList[i].isInsider == false
             )
           {
                
                if(this.LevelList[i].type == "Resistance")
                {
                   if(
                      //this.LevelList[i].highPrice > iHigh(this.strSymbol,this.intPeriod,bar) && //this.Highs[bar] &&//
                      this.LevelList[i].highPrice > this.Highs[bar] &&
                      this.LevelList[i].highPrice < this.res_dn
                     )
                   {
                         this.LevelList[i].isActive = true;
                         //this.ReactiveRemoveMinGap(LevelList[i],i);
                         break;
                   }
                }
           }
     }
     
}


void clsSND::ReactiveRemoveMinGap(CLevel &reactived_level,int arr_idx)
{
    //AFTER REACTIVATION, WE MIGHT HAVE A CLOSED GAP WITHIN LEVEL
    if(arr_idx > 0)
    {
         for(int i = arr_idx; i >= 0; i--)
         {
              if( MathAbs(this.LevelList[i].lowPrice  - reactived_level.highPrice) < Min_Gap * pips(this.strSymbol) ||
                  MathAbs(this.LevelList[i].highPrice - reactived_level.lowPrice) < Min_Gap * pips(this.strSymbol) 
                )
                {
                    this.LevelList[i].isActive = false;
                }
         }
         
    }
}


void clsSND::RemoveInsiderPostReactive()
{
     for(int i = ArraySize(this.LevelList)-1; i >= 1; i--)
     {
          for(int j = i -1; j >= 0; j--)
          {
              if(this.LevelList[i].isActive  &&  this.LevelList[j].isActive )
              {
                 //if(this.LevelList[i].type != this.LevelList[j].type)
                 //{
                        if(this.LevelList[i].highPrice <= this.LevelList[j].highPrice &&
                           this.LevelList[i].lowPrice  >= this.LevelList[j].lowPrice
                          )
                         {
                             //int start_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                             this.LevelList[i].isActive = false;
                             this.LevelList[i].isInsider = true;
                             //Print("Deactiving Inside Bar starting at bar ",start_bar);
                         }
                         
                        
                        if(this.LevelList[i].highPrice > this.LevelList[j].highPrice)
                        {
                             if(MathAbs(this.LevelList[i].lowPrice - this.LevelList[j].highPrice) < Min_Gap * pips(this.strSymbol) ||
                                this.LevelList[j].highPrice > this.LevelList[i].lowPrice
                               )
                             {
                                   //int start_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                                   this.LevelList[i].isActive = false;
                                   this.LevelList[i].isNearGap = true;
                                   //Print("Deactiving Near Gap Bar starting at bar ",start_bar);
                             }
                        }
                        
                        if(this.LevelList[i].lowPrice < this.LevelList[j].lowPrice)
                        {
                             if(MathAbs(this.LevelList[i].highPrice - this.LevelList[j].lowPrice) < Min_Gap * pips(this.strSymbol) ||
                                this.LevelList[i].highPrice > this.LevelList[j].lowPrice //||
                                //this.LevelList[i].highPrice > this.LevelList[j].lowPrice
                               )
                             {
                                   //int start_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                                   this.LevelList[i].isActive = false;
                                   this.LevelList[i].isNearGap = true;
                                   //Print("Deactiving Near Gap Bar starting at bar ",start_bar);
                             }
                        }
                        
                       
                        
                        
                 //}
              }
          }
     }
}


void clsSND::RecoverInactive(int type, CLevel& level, double break_price)
{
     //TYPE 1 : RECOVER SUPPORT, TYPE 2 : RECOVER RESISTANCE
     double lowestPrice  = DBL_MIN;
     double highestPrice = DBL_MAX;
     int sup_idx      = -1;
     int res_idx      = -1;
     if(type == 1)
     {
         //meaning previous resistance break
         Print("Find Reactivable Support at price ",break_price);
         for(int i = ArraySize(this.LevelList) - 1; i >= 0 ; i--)
         {
             if(this.LevelList[i].isActive == false &&
                this.LevelList[i].isInterSected == true &&
                this.LevelList[i].type     == "Support" &&
                //this.LevelList[i].isBreak  == false &&
                this.LevelList[i].lowPrice < break_price 
               )
             {
                  //if(this.LevelList[i].lowPrice > lowestPrice)
                  //{
                       sup_idx = i;
                       //int bar_sup = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                       Print("Sup idx is ",sup_idx);
                       //Print("Break Support Price is ",break_price);
                       Print("Finding support Lowest Level is ",this.LevelList[i].lowPrice);
                       //Print("Finding support from support ",bar_sup);
                       //Print("Support index is ",sup_idx);
                       lowestPrice = this.LevelList[i].lowPrice;
                       this.LevelList[i].isActive = true;
                       break;
                  //}
             }
         }
     }
     else
     {
        if(type == 2)
        {
            Print("Find Reactivable Resistance at price ",break_price);
            //meaning previous resistance break
            for(int i = ArraySize(this.LevelList)-1; i >= 0; i--)
            {
                if(this.LevelList[i].isActive == false &&
                   this.LevelList[i].isInterSected == true &&
                   this.LevelList[i].type          == "Resistance" &&
                   //this.LevelList[i].isBreak  == false &&
                   this.LevelList[i].highPrice > break_price
                  )
                {
                     //if(this.LevelList[i].highPrice < highestPrice)
                     //{
                          res_idx = i;
                          //int bar_res = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                          //Print("Res idx is ",res_idx);
                          //Print("Break Resistance Price is ",break_price);
                          //Print("Finding resistance Highest Level is ",this.LevelList[i].highPrice);
                          //Print("Finding resistance from resistance ",bar_res);
                          highestPrice = this.LevelList[i].highPrice;
                          this.LevelList[i].isActive = true;
                          break;
                     //}
                }
            }
        }
      }
     //if(sup_idx > 0) this.LevelList[sup_idx].isActive = true; this.LevelList[sup_idx].isInterSected = false;
     //if(res_idx > 0) this.LevelList[res_idx].isActive = true; this.LevelList[res_idx].isInterSected = false;
}

/***************************************************
 * Removes/Flips levels when they are tested/broken
 ***************************************************/
void clsSND::UpdateLevels(int bar)
{
     bool res_reactivate = false;
     bool sup_reactivate = false;
     //Print("Current array size is ",ArraySize(this.LevelList));
     
     for(int k = 0; k < ArraySize(this.LevelList); k++)
     {
         if(this.LevelList[k].isActive  ||
           (this.LevelList[k].isActive == false && this.LevelList[k].isInterSected == true)
          )
        {
           
           if(this.LevelList[k].type == "Support")
           {
              //support break in 1 candle
              //if(iOpen(this.strSymbol,this.intPeriod,bar) >= this.LevelList[k].highPrice  && iClose(this.strSymbol,this.intPeriod,bar) < this.LevelList[k].lowPrice)
              if(this.Opens[bar] >= this.LevelList[k].highPrice  && this.Closes[bar] < this.LevelList[k].lowPrice)
              {
                this.LevelList[k].type = "Resistance";
                //if(iHigh(this.strSymbol,this.intPeriod,bar) > this.LevelList[k].highPrice)
                if(this.Highs[bar] > this.LevelList[k].highPrice)
                      {
                        this.LevelList[k].isActive = false;
                        this.LevelList[k].isBreak  = true;
                        //int lvl_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[k].startDate);
                      }
              }
              //support break in multiple candles
              else
              {
                 if(
                 //iLow(this.strSymbol,this.intPeriod,bar) < this.LevelList[k].lowPrice)
                    this.Lows[bar] < this.LevelList[k].lowPrice
                   )
                 {
                     this.LevelList[k].isActive = false;
                     this.LevelList[k].isBreak  = true;
                     //int lvl_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[k].startDate);
                 }
                  
               }
            }
          
            if(this.LevelList[k].type == "Resistance")
              {
                  //resistance break
                  //if(iOpen(this.strSymbol,this.intPeriod,bar) <= this.LevelList[k].lowPrice  && iClose(this.strSymbol,this.intPeriod,bar) > this.LevelList[k].highPrice)
                  if(this.Opens[bar] <= this.LevelList[k].lowPrice  && this.Closes[bar] > this.LevelList[k].highPrice)
                  {
                     this.LevelList[k].type = "Support";
                     //if(iLow(this.strSymbol,this.intPeriod,bar) < this.LevelList[k].lowPrice)
                       if(this.Lows[bar] < this.LevelList[k].lowPrice)
                       {
                           this.LevelList[k].isActive = false;
                           this.LevelList[k].isBreak  = true;
                           //int lvl_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[k].startDate);
                       }
                  }
                  //resistance break in multiple candles
                  else
                  {
                     //if(iHigh(this.strSymbol,this.intPeriod,bar) > this.LevelList[k].highPrice)
                      if(this.Highs[bar] > this.LevelList[k].highPrice)
                      {
                        this.LevelList[k].isActive = false;
                        this.LevelList[k].isBreak  = true;
                        //int lvl_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[k].startDate);
                      }
                  }
              
           } 
          }    
       
     }
        
}

int clsSND::intGetEngulfingTrend(void)
{
    //always refer to previous one bar
    if(this.intGetEngulfingCandleSignal1(1) || this.intGetEngulfingCandleSignal2(1))
    {
         //this.
    }
    return false;
}


bool clsSND::blIsGreenCandle(int bar)
{
     //Alert("Bar is ",bar);
     return (this.Closes[bar]>this.Opens[bar]);
     //return (iClose(this.strSymbol,this.intPeriod,bar)>iOpen(this.strSymbol,this.intPeriod,bar));
}

int clsSND::intGetEngulfingCandleSignal1(int bar)
{
     //Alert("Bar A is ",bar);
     //if(this.blIsGreenCandle(bar+1) && !blIsGreenCandle(bar) && iClose(this.strSymbol,this.intPeriod,bar) < iLow(this.strSymbol,this.intPeriod,bar+1))
     if(this.blIsGreenCandle(bar+1) && !blIsGreenCandle(bar) && this.Closes[bar] < this.Lows[bar+1])
     {
      return -1;
     }
     //if(!this.blIsGreenCandle(bar+1) && this.blIsGreenCandle(bar) && iClose(this.strSymbol,this.intPeriod,bar) > iHigh(this.strSymbol,this.intPeriod,bar+1))
     if(!this.blIsGreenCandle(bar+1) && this.blIsGreenCandle(bar) && this.Closes[bar] > this.Highs[bar+1])
     {
      return 1;
     }
     return 0;
}

/**********************************************************
 * Gets engulging signal Type 2
 **********************************************************/
int clsSND::intGetEngulfingCandleSignal2(int bar)
{
   //Alert("Bar B is ",bar);
   //if(this.blIsGreenCandle(bar+2) && !this.blIsGreenCandle(bar+1) && !this.blIsGreenCandle(bar) && iClose(this.strSymbol,this.intPeriod,bar+1) >= iOpen(this.strSymbol,this.intPeriod,bar+2) && iClose(this.strSymbol,this.intPeriod,bar) < iLow(this.strSymbol,this.intPeriod,bar+2))
   if(this.blIsGreenCandle(bar+2) && !this.blIsGreenCandle(bar+1) && !this.blIsGreenCandle(bar) && this.Closes[bar+1] >= this.Opens[bar+2] && this.Closes[bar] < this.Lows[bar+2])
   {
   return -1;
   }
   //if(!this.blIsGreenCandle(bar+2) && this.blIsGreenCandle(bar+1) && this.blIsGreenCandle(bar) && iClose(this.strSymbol,this.intPeriod,bar+1) <= iOpen(this.strSymbol,this.intPeriod,bar+2) && iClose(this.strSymbol,this.intPeriod,bar) > iHigh(this.strSymbol,this.intPeriod,bar+2))
   if(!this.blIsGreenCandle(bar+2) && this.blIsGreenCandle(bar+1) && this.blIsGreenCandle(bar) && this.Closes[bar+1] <= this.Opens[bar+2] && this.Closes[bar] > this.Highs[bar+2])
   {
   return 1;
   }
   return 0;
}

void clsSND::FindSnR(int bar)
{
   // Alert("Find SNR Bar is ",bar);
    int signal1 = this.intGetEngulfingCandleSignal1(bar);
    int signal2 = this.intGetEngulfingCandleSignal2(bar);
    //int signal1 = 1;
    //int signal2 = 1;
    //RESET ON EACH RUN
    this.strSNRType = "";
    this.intEngulfedCandleDist = 0;
   
    if(signal1 == 1)
    {
      this.strSNRType = "Support";
      this.intEngulfedCandleDist = 1;
    }
   else
   {
     if(signal2 == 1)
     {
       this.strSNRType = "Support";
       this.intEngulfedCandleDist = 2;
     }
     else
     {
         if(signal1 == -1)
         {
          this.strSNRType = "Resistance";
          this.intEngulfedCandleDist = 1;
         }
         else
         {
            if(signal2 == -1)
            {
            this.strSNRType = "Resistance";
            this.intEngulfedCandleDist = 2;
            }
         }
      }
    }
    
}


void clsSND::UpdateSnR(int bar)
{
    //WE ADD ANY NEW LEVEL INTO EXISTING

     if(this.strSNRType != "")
     {
        CLevel level;

        if(this.strSNRType == "Support")
        {
            double lowestPrice = DBL_MAX;
            for(int k=bar; k <= bar+this.intEngulfedCandleDist; k++)
            {
               //lowestPrice = MathMin(iLow(this.strSymbol,this.intPeriod,k),lowestPrice);
               lowestPrice = MathMin(this.Lows[k],lowestPrice);
            }
   
            //level.highPrice = iHigh(this.strSymbol,this.intPeriod,bar+this.intEngulfedCandleDist); //this.Highs[bar+this.intEngulfedCandleDist];//
            level.highPrice = Highs[bar+this.intEngulfedCandleDist];
            level.lowPrice = lowestPrice;
        }
        else
        {
            if(this.strSNRType == "Resistance")
              {
               double highestPrice = DBL_MIN;
               for(int k=bar; k <= bar+this.intEngulfedCandleDist; k++)
               {
                  //highestPrice = MathMax(iHigh(this.strSymbol,this.intPeriod,k),highestPrice);
                  highestPrice = MathMax(this.Highs[k],highestPrice);
               }
   
               level.highPrice = highestPrice;
               //level.lowPrice = iLow(this.strSymbol,this.intPeriod,bar+this.intEngulfedCandleDist); //this.Lows[bar+this.intEngulfedCandleDist];//
               level.lowPrice = this.Lows[bar+this.intEngulfedCandleDist];
              }
        }

      level.isActive = true;
      //level.startDate = iTime(this.strSymbol,this.intPeriod,bar+this.intEngulfedCandleDist); //this.Times[bar+this.intEngulfedCandleDist-1];//
      level.startDate = this.Times[bar+this.intEngulfedCandleDist];
      if(level.startDate == 0)
      {
          Alert("Date 0 at bar",bar);
      }
      level.type = this.strSNRType;
      level.SNDBaseDist = this.intEngulfedCandleDist;
      RemoveIntersectingLevels(level);
      AddToLevelList(level);
    }
}


void clsSND::RemoveIntersectingLevels(CLevel& addedLevel)
{
   for(int k = 0; k < ArraySize(this.LevelList); k++)
   {
     if(!this.LevelList[k].isActive)
     {
      continue;
     }

     if(addedLevel.lowPrice > this.LevelList[k].highPrice)
     {
      //above
     }
     else
     {
        if(addedLevel.highPrice < this.LevelList[k].lowPrice)
        {
         //below
        }
        else
        {
             //intersecting
            addedLevel.HideIdx = k;
            //int stored_hide_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[addedLevel.HideIdx].startDate);
            this.LevelList[k].isActive = false;
            this.LevelList[k].isInterSected  = true;
            
        }
      }
   }
}


void clsSND::FindRoundNumber(void)
{
   for(int i = 0; i < ArraySize(this.LevelList); i++)
   {
      if(this.LevelList[i].isActive)
      {
           double initial = this.LevelList[i].lowPrice;
           double range   = Round_Number * MarketInfo(this.strSymbol,MODE_POINT);
           int factor     = (int)MathRound(initial / range);
           double start_range = factor * range;
           //clear the old data first 
           ArrayFree(this.LevelList[i].RoundNumber);
           for (double j = start_range; j <= this.LevelList[i].highPrice; j+= range)
           {
               if (j >= this.LevelList[i].lowPrice)
               {
                  ArrayCopy(this.LevelList[i].RoundNumber,this.LevelList[i].RoundNumber,1,0);
                  this.LevelList[i].RoundNumber[0] = j;
               }
           }
      }
   }
}

void clsSND::AddToLevelList(CLevel& level)
{
   if(level.isInsider)
   {
      //int insider_start = iBarShift(this.strSymbol,this.intPeriod,level.startDate);
      int insider_start = intBarByDate(Times,level.startDate);
      Print("Store Insider New Zone starting from ",insider_start," active status of ",level.isActive);
   }
   int size = ArraySize(this.LevelList);
   ArrayResize(this.LevelList,size+1);
   this.LevelList[size] = level;
}


void clsSND::DrawRoundNumberLine(CLevel &level)
{
   for(int i = 0; i < ArraySize(level.RoundNumber); i++)
   {
         string ob_name = this.strIdentifier + " Round Number " + (string)level.RoundNumber[i];
         ObjectCreate(0,ob_name,OBJ_TREND,0,level.startDate,level.RoundNumber[i],iTime(ChartSymbol(),ChartPeriod(),0),level.RoundNumber[i]);
         //ObjectCreate(0,ob_name,OBJ_TREND,0,iTime(ChartSymbol(),ChartPeriod(),0),level.RoundNumber[i],this.LevelList[i].startDate,level.RoundNumber[i]);
         ObjectSetInteger(0,ob_name,OBJPROP_COLOR,Round_Number_Line_Color);
         ObjectSetInteger(0,ob_name,OBJPROP_WIDTH,2);
   }
}

void clsSND::PlotZone(int type)
{
   //TYPE 1 : NORMAL, 2 : FRESH
   if (type == 1)
   {
         for(int i = 0; i < ArraySize(this.LevelList); i++)
         {
            //Print("Timeframe of ",this.intPeriod," iii is ",ArraySize(this.LevelList));
            if(this.LevelList[i].isActive)
            {
              //DO SOME COUNTING
              if(this.LevelList[i].type == "Support") this.intSupCount += 1;
              if(this.LevelList[i].type  == "Resistance") this.intResCount += 1;
              //DRAW OPTION
              //int start_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
              //if(this.intPeriod == 1)
              //{
                 //Alert("Start Date in TF ",this.intPeriod, " is ",this.LevelList[i].startDate);
                 //Alert("Start Bar in TF ",this.intPeriod, " is ",start_bar, " with type of ",this.LevelList[i].type);
              //}
              if(DrawSNDLevel)  this.DrawRectangle(this.LevelList[i].highPrice, this.LevelList[i].startDate, this.LevelList[i].lowPrice, iTime(ChartSymbol(),ChartPeriod(),0), this.LevelList[i].type);
              if(DrawNumberLine)this.DrawRoundNumberLine(this.LevelList[i]);
            }
         }
   }
   else
   {
         if (type == 2)
         {
               for(int i = 0; i < ArraySize(this.FreshLevelList); i++)
               {
                  //Print("i is ",i);
                  if(this.FreshLevelList[i].isActive)
                  {
                    //DO SOME COUNTING
                    if(this.FreshLevelList[i].type == "Support") this.intSupFreshCount += 1;
                    if(this.FreshLevelList[i].type  == "Resistance") this.intResFreshCount += 1;
                    //DRAW OPTION
                    int start_bar = iBarShift(this.strSymbol,this.intPeriod,this.FreshLevelList[i].startDate);
                    if(DrawSNDLevel)  this.DrawRectangle(this.FreshLevelList[i].highPrice, this.FreshLevelList[i].startDate, this.FreshLevelList[i].lowPrice, iTime(ChartSymbol(),ChartPeriod(),0), this.FreshLevelList[i].type);
                    if(DrawNumberLine)this.DrawRoundNumberLine(this.FreshLevelList[i]);
                  }
                }
         }
   }
}



void clsSND::DrawLevel(void)
{
   if(this.blDrawMode)
   {
      //RESET ON EACH RUN
      this.intSupCount = 0;
      this.intResCount = 0;
      this.DeleteLevel();
      
      
      if(this.blFreshMode)   
      {
         this.PlotZone(2);
      }
      else
      {
         //Print(this.intPeriod," Plot zone 1");
         this.PlotZone(1);
      }
   }
}

void clsSND::DeleteLevel(void)
{
   //Print("Prepare Delete");
   for (int i=ObjectsTotal()-1; i >= 0; i--) 
   {
      string obj_name = ObjectName(i); 
      string level_to_delete = this.strIdentifier +"-LEVEL";
      string line_to_delete  = this.strIdentifier +" Round Number";
      if(StringFind(obj_name,level_to_delete)>=0)
      {
          //Print("Deleting ",obj_name);
          ObjectDelete(0,obj_name);
      }
      if(StringFind(obj_name,line_to_delete)>=0)
      {
          //Print("Deleting ",obj_name);
          ObjectDelete(0,obj_name);
      }
   }
   ChartRedraw();
}

void clsSND::DrawRectangle(double price1, datetime time1, double price2, datetime time2, string type="")
{
   string name = this.strIdentifier +"-LEVEL" + "-" + type + "-" + IntegerToString(time1);
   color clr = (type == "Support" ? this.sup_color : this.res_color);
   //Print("Drawing Rectangle");
   if(ObjectCreate(0,name,OBJ_RECTANGLE,0,time1,price1,time2,price2))
   {
         //Print("Time 1 ",time1);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0, name, OBJPROP_FILL, true);
         int index=iBarShift(this.strSymbol,PERIOD_CURRENT,time1);
   }
}


void clsSND::FindNearestLevel(int cur_bar)
{
   this.res_up_prev = this.res_up;
   this.res_dn_prev = this.res_dn;
   this.sup_up_prev = this.sup_up;
   this.sup_dn_prev = this.sup_dn;
   this.res_bar     = 0;
   this.sup_bar     = 0;
   this.res_up      = 0;
   this.res_dn      = 0;
   this.sup_up      = 0;
   this.sup_dn      = 0;
   double lowestPrice  = DBL_MIN;
   double highestPrice = DBL_MAX;
   //RESET ON EACH RUN
   this.intLastResIdx = -1;
   this.intLastSupIdx = -1;    
   //Print("Searching within ",cur_bar);
   for(int i = 0; i < ArraySize(this.LevelList); i++)
   {
      if(this.LevelList[i].isActive)
      {
          //Print("Active Level Found");
          if(this.LevelList[i].type == "Support")
          {
               //Print("Support Found");
               if(//this.LevelList[i].highPrice > iClose(this.strSymbol,this.intPeriod,cur_bar) ||
                  //this.LevelList[i].lowPrice <  iLow(this.strSymbol,this.intPeriod,cur_bar) //this.Lows[cur_bar]//  
                  this.LevelList[i].lowPrice < this.Lows[cur_bar]
                 )
               {
                   //we need find the maximum
                   if(this.LevelList[i].highPrice > lowestPrice)
                   {
                       this.sup_up = this.LevelList[i].highPrice;
                       this.sup_dn = this.LevelList[i].lowPrice;
                       this.sup_bar = intBarByDate(Times,this.LevelList[i].startDate);
                       //this.sup_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                       this.sup_start_time = this.LevelList[i].startDate;
                       this.intLastSupIdx = i;
                       lowestPrice = this.LevelList[i].highPrice;
                       this.latest_sup_lvl = this.LevelList[i];
                   }
               }
          }
          else
          {
                if(this.LevelList[i].type == "Resistance")
                {
                     //Alert("Cur Bar is ",cur_bar);
                     //Print("Resistance Found");
                     if(//this.LevelList[i].lowPrice < iClose(this.strSymbol,this.intPeriod,cur_bar) ||
                        //this.LevelList[i].highPrice > iHigh(this.strSymbol,this.intPeriod,cur_bar) //this.Highs[cur_bar] //
                        this.LevelList[i].highPrice > this.Highs[cur_bar]
                       )
                     {
                         //we need find the minimum
                         if(this.LevelList[i].lowPrice < highestPrice)
                         {
                             //Print("Optimal Resistanec Found");
                             this.res_up = this.LevelList[i].highPrice;
                             this.res_dn = this.LevelList[i].lowPrice;
                             this.res_bar = intBarByDate(Times,this.LevelList[i].startDate);
                             //this.res_bar = iBarShift(this.strSymbol,this.intPeriod,this.LevelList[i].startDate);
                             this.res_start_time = this.LevelList[i].startDate;
                             this.intLastResIdx = i;
                             highestPrice = this.LevelList[i].lowPrice;
                             this.latest_res_lvl = this.LevelList[i];
                         }
                     }
                }
          }
      }
   }
   this.StoreArray(this.res_up,this.res_up_list,this.intMaxStoreCount);
   this.StoreArray(this.res_dn,this.res_dn_list,this.intMaxStoreCount);
   this.StoreArray(this.sup_up,this.sup_up_list,this.intMaxStoreCount);
   this.StoreArray(this.sup_dn,this.sup_dn_list,this.intMaxStoreCount);
   
   /*
   if(ArraySize(this.res_up_list)>1)//this.intMaxStoreCount) 
   {
        Print("Current Res Up is ",this.res_up_list[0]);
        Print("Previous Res Up is ",this.res_up_list[1]);
        Print("Res Up Size is ",ArraySize(this.res_up_list));
   }
   */
   
}

void clsSND::FinalDirectionCheck()
{
   
   double sel_sup_up=0; double sel_sup_dn=0; double sel_res_up=0; double sel_res_dn=0;
   int    sel_sup_count=0; int sel_res_count=0;
   if(this.blFreshMode == false)
   {
        sel_sup_up = this.sup_up;
        sel_sup_dn = this.sup_dn;
        sel_res_up = this.res_up;
        sel_res_dn = this.res_dn;
        sel_sup_count = this.intSupCount;
        sel_res_count = this.intResCount;
   }
   if(this.blFreshMode == true)
   {
        //Alert("swap fresh here");
        //Alert("Sup Up Fresh Is ", this.sup_up_fresh);
        sel_sup_up = this.sup_up_fresh;
        sel_sup_dn = this.sup_dn_fresh;
        sel_res_up = this.res_up_fresh;
        sel_res_dn = this.res_dn_fresh;
        sel_sup_count = this.intSupFreshCount;
        sel_res_count = this.intResFreshCount;
   }
   Print((string)this.intPeriod+" Checking Final Direction with Sup Up"+(string)sel_sup_up+" Res Up of "+(string)sel_res_up);
   string debug_code = "";
   static int prev_trend = 0;
   if(this.intFinalDirection == 1)
   {
       Print("Inside Trend 1 of ",this.intPeriod);
       if(MarketInfo(this.strSymbol,MODE_BID) <= sel_res_up && MarketInfo(this.strSymbol,MODE_BID) >= sel_res_dn &&
           sel_res_up != 0 && sel_res_dn != 0
          )
       {
           Print("Inside Trend 1 G of ",this.intPeriod);
           this.intFinalDirection = -1; //if from bull raise to SUPPLY zone, change to bear
           debug_code = "G";
       } 
       if(MarketInfo(this.strSymbol,MODE_BID) < sel_sup_up && MarketInfo(this.strSymbol,MODE_BID) < sel_sup_dn &&
           sel_sup_up != 0 && sel_sup_dn != 0
          )
       {
           Print("Inside Trend 1 H of ",this.intPeriod);
           this.intFinalDirection = -1; //if BULL support zone break, the current direction change
           debug_code = "H";
           //but we wait until a new bar close confirmation
       } 
   }
   
   if(this.intFinalDirection == -1)
   {
       Print("Inside Trend -1 of ",this.intPeriod);
       if(MarketInfo(this.strSymbol,MODE_BID) <= sel_sup_up && MarketInfo(this.strSymbol,MODE_BID) >= sel_sup_dn &&
           sel_sup_up != 0 && sel_sup_dn != 0
          )
       {
           Print("Inside Trend -1 I of ",this.intPeriod);
           this.intFinalDirection = 1; //if from bear drop to DEMAND zone, change to bull
           debug_code = "I";
       } 
       if(MarketInfo(this.strSymbol,MODE_BID) > sel_res_up && MarketInfo(this.strSymbol,MODE_BID) > sel_res_dn &&
           sel_res_up != 0 && sel_res_dn != 0
          )
       {
           Print("Inside Trend -1 J of ",this.intPeriod);
           this.intFinalDirection = 1; //if BEAR resistance zone break, the current direction change
           debug_code = "J";
           //but we wait until a new bar close confirmation
       } 
   }
   Print(this.intPeriod," Pre comment final direction is ",this.intFinalDirection);
   Print(this.intPeriod," Previous Trend is ",prev_trend);
   //if(prev_trend != this.intFinalDirection || prev_trend == 0)
   //{
      //COMMENT ON CHART
      if(this.blCommentMode)
      {
         //Print("Trying to comment direction at SND ",this.intPeriod);
         Comment("");
         string use_fresh = this.blFreshMode ? " Using Fresh Zone Only" : " Using Normal Zone";
         string out  = "\nSND Direction Based on TF "+(string)this.intPeriod+use_fresh;
         string comm = StringFormat("Support Levels: %d | Resistance Levels: %d", sel_sup_count, sel_res_count);
         comm += StringFormat("\nDirection: %s", this.intFinalDirection > 0 ? "BULLISH" : (this.intFinalDirection < 0 ? "BEARISH" : ""));
         //comm += "\n[SAVED] High is : "+ (string)this.Highs[0]+" Low is "+(string)this.Lows[0]+ " Open is "+(string)this.Opens[0]+" Close is "+(string) this.Closes[0];
         comm += "\n[REAL] High is : "+ (string)iHigh(this.strSymbol,this.intPeriod,1)+" Low is "+(string)iLow(this.strSymbol,this.intPeriod,1)+ " Open is "+(string)iOpen(this.strSymbol,this.intPeriod,1)+" Close is "+(string) iClose(this.strSymbol,this.intPeriod,1);
         comm += "\nTotal Level is "+(string)ArraySize(this.LevelList);
         comm += "\nDebug Code is "+debug_code;
         comm += "\nNearest Sup Up is "+(string)sel_sup_up+ "with Sup Dn of "+(string)sel_sup_dn;//+" with start time of "+(string);
         comm += "\nNearest Res Up is "+(string)sel_res_up+ "with Res Dn of "+(string)sel_res_dn;
         comm += "\nCandle size is "+(string)ArraySize(this.Closes);
         comm += out;
         Comment(comm);
      }
      //prev_trend = this.intFinalDirection;
   //}
}


int clsSND::intCurrentDirection(int cur_bar, SND_MODE mode = 1)
{    
   this.intFinalDirection = 0;
   double sel_sup_up=0; double sel_sup_dn=0; double sel_res_up=0; double sel_res_dn=0;
   datetime sel_sup_start_date=0; datetime sel_res_start_date=0;
   int    sel_sup_count=0; int sel_res_count=0;
   if(mode == 1)
   {
        sel_sup_up = this.sup_up;
        sel_sup_dn = this.sup_dn;
        sel_res_up = this.res_up;
        sel_res_dn = this.res_dn;
        sel_sup_count = this.intSupCount;
        sel_res_count = this.intResCount;
        sel_sup_start_date = this.sup_start_time;
        sel_res_start_date = this.res_start_time;
   }
   if(mode == 2)
   {
        //Alert("swap fresh here");
        //Alert("Sup Up Fresh Is ", this.sup_up_fresh);
        sel_sup_up = this.sup_up_fresh;
        sel_sup_dn = this.sup_dn_fresh;
        sel_res_up = this.res_up_fresh;
        sel_res_dn = this.res_dn_fresh;
        sel_sup_count = this.intSupFreshCount;
        sel_res_count = this.intResFreshCount;
        sel_sup_start_date = this.sup_start_time_fresh;
        sel_res_start_date = this.res_start_time_fresh;
   }
   
   //get latest SnD
   int value = 0;
   //Alert("Selected Sup Up Is ", sel_sup_up);
   //Alert("Selected Res Dn Is ", sel_res_dn);
   string debug_code = "";
   //for(int i = cur_bar ; i < CandleLimit; i++)
   for(int i = cur_bar ; i < ArraySize(this.Highs)-3; i++)
   {    
        //Alert("looping i of ",i);
        if(this.intGetEngulfingCandleSignal1(i) == 1) 
        {  
          //int    lowest_idx = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,2,i);
          int    lowest_idx = intLowestIdx(Lows,2,i);
          //double lowest  = iLow(this.strSymbol,this.intPeriod,lowest_idx);
          double lowest     = Lows[lowest_idx]; 
          //int    lowest_all_idx = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,i-cur_bar+1,cur_bar);
          int    lowest_all_idx = intLowestIdx(Lows,i-cur_bar+1,cur_bar);
          //double lowest_all = iLow(this.strSymbol,this.intPeriod,lowest_all_idx);
          double lowest_all = Lows[lowest_all_idx];
          if(lowest_all >= lowest)
          {
             value = 1; 
             debug_code = "A";
             break;
          }
        }
        if(this.intGetEngulfingCandleSignal1(i) == -1) 
        {  
          //int    highest_idx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,2,i);
          int    highest_idx = intHighestIdx(Highs,2,i);
          //Alert("Highest idx is ",highest_idx);
          //ExpertRemove();
          //double highest = iHigh(this.strSymbol,this.intPeriod,highest_idx);
          double highest = Highs[highest_idx];
          //int    highest_all_idx = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,i-cur_bar+1,cur_bar);
          int    highest_all_idx = intHighestIdx(Highs,i-cur_bar+1,cur_bar);
          //double highest_all = iHigh(this.strSymbol,this.intPeriod,highest_all_idx);
          double highest_all = Highs[highest_all_idx];
          if(highest_all <= highest)
          {
             value = -1; 
             debug_code = "B";
             break;
          }
        }
   }
   
   
   //COMMENT ON CHART
   if(this.blCommentMode)
   {
      //Print("Trying to comment direction at SND ",this.intPeriod);
      Comment("");
      string use_fresh = this.blFreshMode ? " Using Fresh Zone Only" : " Using Normal Zone";
      string out  = "\nSND Direction Based on TF "+(string)this.intPeriod+use_fresh;
      string comm = StringFormat("Support Levels: %d | Resistance Levels: %d", sel_sup_count, sel_res_count);
      comm += StringFormat("\nDirection: %s", value > 0 ? "BULLISH" : (value < 0 ? "BEARISH" : ""));
      //comm += "\n[SAVED] High is : "+ (string)this.Highs[0]+" Low is "+(string)this.Lows[0]+ " Open is "+(string)this.Opens[0]+" Close is "+(string) this.Closes[0];
      comm += "\n[REAL] High is : "+ (string)iHigh(this.strSymbol,this.intPeriod,1)+" Low is "+(string)iLow(this.strSymbol,this.intPeriod,1)+ " Open is "+(string)iOpen(this.strSymbol,this.intPeriod,1)+" Close is "+(string) iClose(this.strSymbol,this.intPeriod,1);
      comm += "\nTotal Level is "+(string)ArraySize(this.LevelList);
      comm += "\nDebug Code is "+debug_code;
      comm += "\nNearest Sup Up is "+(string)sel_sup_up+ "with Sup Dn of "+(string)sel_sup_dn+ " start date of "+(string)sel_sup_start_date;
      comm += "\nNearest Res Up is "+(string)sel_res_up+ "with Res Dn of "+(string)sel_res_dn+ " start date of "+(string)sel_res_start_date;
      comm += "\nCandle size is "+(string)ArraySize(this.Closes);
      comm += out;
      Comment(comm);
   }
   this.intFinalDirection = value;
   return(value);
}



/*
int clsSND::intCurrentDirection(int cur_bar, SND_MODE mode = 1)
{    
   this.intFinalDirection = 0;
   double sel_sup_up=0; double sel_sup_dn=0; double sel_res_up=0; double sel_res_dn=0;
   datetime sel_sup_start_date=0; datetime sel_res_start_date=0;
   int    sel_sup_count=0; int sel_res_count=0;
   if(mode == 1)
   {
        sel_sup_up = this.sup_up;
        sel_sup_dn = this.sup_dn;
        sel_res_up = this.res_up;
        sel_res_dn = this.res_dn;
        sel_sup_count = this.intSupCount;
        sel_res_count = this.intResCount;
        sel_sup_start_date = this.sup_start_time;
        sel_res_start_date = this.res_start_time;
   }
   if(mode == 2)
   {
        //Alert("swap fresh here");
        //Alert("Sup Up Fresh Is ", this.sup_up_fresh);
        sel_sup_up = this.sup_up_fresh;
        sel_sup_dn = this.sup_dn_fresh;
        sel_res_up = this.res_up_fresh;
        sel_res_dn = this.res_dn_fresh;
        sel_sup_count = this.intSupFreshCount;
        sel_res_count = this.intResFreshCount;
        sel_sup_start_date = this.sup_start_time_fresh;
        sel_res_start_date = this.res_start_time_fresh;
   }
   
   //get latest SnD
   int value = 0;
   //Alert("Selected Sup Up Is ", sel_sup_up);
   //Alert("Selected Res Dn Is ", sel_res_dn);
   string debug_code = "";
   for(int i = cur_bar ; i < CandleLimit; i++)
   //for(int i = cur_bar ; i < ArraySize(this.Highs)-2; i++)
   {    
       if(iHigh(this.strSymbol,this.intPeriod,i)  > sel_sup_up &&//this.LevelList[this.intLastSupIdx].highPrice &&
          iLow(this.strSymbol,this.intPeriod,i+1) < sel_sup_up &&//this.LevelList[this.intLastSupIdx].highPrice &&
          (iHigh(this.strSymbol,this.intPeriod,i)  < sel_res_dn || sel_res_dn == 0)//&&//this.LevelList[this.intLastResIdx].lowPrice
          //sel_sup_up != 0 && sel_res_dn != 0
         )
       
      {
           value = 1;
           debug_code = "A";
           break;
       }
       else
       {
          if(iLow(this.strSymbol,this.intPeriod,i)    < sel_res_dn &&//this.LevelList[this.intLastResIdx].lowPrice &&
             iHigh(this.strSymbol,this.intPeriod,i+1) > sel_res_dn &&//this.LevelList[this.intLastResIdx].lowPrice &&
             (iLow(this.strSymbol,this.intPeriod,i)    > sel_sup_up || sel_sup_up == 0)//&&//this.LevelList[this.intLastSupIdx].highPrice
             //sel_res_dn != 0 && sel_sup_up != 0
            )
          
          {
              value = -1;
              debug_code = "B";
              break;
          }
       }
   }
   
   if(value == 1)
   {if(this.intGetEngulfingCandleSignal1(cur_bar) == -1) value = -1; debug_code = "C";}
   else{
      if(value == -1)
      {if(this.intGetEngulfingCandleSignal1(cur_bar) == 1) value = 1; debug_code = "D";}
   }
   
   //INSIDE RESISTANCE/SUPPORT CHECK
   if(MarketInfo(this.strSymbol,MODE_BID) >= sel_res_dn && sel_res_dn != 0 &&
      MarketInfo(this.strSymbol,MODE_BID) <= sel_res_up && sel_res_up != 0
     )
   //if(this.Closes[cur_bar] > sel_res_dn && sel_res_dn != 0)
   //if(iClose(this.strSymbol,this.intPeriod,cur_bar) > sel_res_dn)//this.LevelList[this.intLastResIdx].lowPrice)
   {
       value = -1;
       debug_code = "E";
       
   }
   if(MarketInfo(this.strSymbol,MODE_BID)  <= sel_sup_up && sel_sup_up != 0 &&
      MarketInfo(this.strSymbol,MODE_BID)  >= sel_sup_dn && sel_sup_dn != 0
     )
   //if(this.Closes[cur_bar] < sel_sup_up && sel_sup_up != 0)
   //if(iClose(this.strSymbol,this.intPeriod,cur_bar) < sel_sup_up)//this.LevelList[this.intLastSupIdx].highPrice)
   {
       value = 1;
       debug_code = "F";
   }
   
   if(debug_code == "E" || debug_code == "D")
   {
       //BEAR BROKEN, CHANGE TO BULL
       if(MarketInfo(this.strSymbol,MODE_BID) > sel_res_dn && sel_res_dn != 0 &&
          MarketInfo(this.strSymbol,MODE_BID) > sel_res_up && sel_res_up != 0
         )
       {
           //value = 1;
           //debug_code = "G";
           this.Updater(TimeCurrent(),false,false);
       }
   }
   if(debug_code == "F" || debug_code == "C")
   {
       //BULL BROKEN, CHANGE TO BEAR
       if(MarketInfo(this.strSymbol,MODE_BID)  < sel_sup_up && sel_sup_up != 0 &&
          MarketInfo(this.strSymbol,MODE_BID)  < sel_sup_dn && sel_sup_dn != 0
         )
       {
           //value = -1;
           //debug_code = "H";
           this.Updater(TimeCurrent(),false,false);
       }
   }
   
   
   //COMMENT ON CHART
   if(this.blCommentMode)
   {
      //Print("Trying to comment direction at SND ",this.intPeriod);
      Comment("");
      string use_fresh = this.blFreshMode ? " Using Fresh Zone Only" : " Using Normal Zone";
      string out  = "\nSND Direction Based on TF "+(string)this.intPeriod+use_fresh;
      string comm = StringFormat("Support Levels: %d | Resistance Levels: %d", sel_sup_count, sel_res_count);
      comm += StringFormat("\nDirection: %s", value > 0 ? "BULLISH" : (value < 0 ? "BEARISH" : ""));
      //comm += "\n[SAVED] High is : "+ (string)this.Highs[0]+" Low is "+(string)this.Lows[0]+ " Open is "+(string)this.Opens[0]+" Close is "+(string) this.Closes[0];
      comm += "\n[REAL] High is : "+ (string)iHigh(this.strSymbol,this.intPeriod,1)+" Low is "+(string)iLow(this.strSymbol,this.intPeriod,1)+ " Open is "+(string)iOpen(this.strSymbol,this.intPeriod,1)+" Close is "+(string) iClose(this.strSymbol,this.intPeriod,1);
      comm += "\nTotal Level is "+(string)ArraySize(this.LevelList);
      comm += "\nDebug Code is "+debug_code;
      comm += "\nNearest Sup Up is "+(string)sel_sup_up+ "with Sup Dn of "+(string)sel_sup_dn+ " start date of "+(string)sel_sup_start_date;
      comm += "\nNearest Res Up is "+(string)sel_res_up+ "with Res Dn of "+(string)sel_res_dn+ " start date of "+(string)sel_res_start_date;
      comm += "\nCandle size is "+(string)ArraySize(this.Closes);
      comm += out;
      Comment(comm);
   }
   this.intFinalDirection = value;
   return(value);
}
*/

void clsSND::DrawLabel(string name, int xCord, int yCord, string text)
{
   //Print("Drawing watermark");
   name = this.strIdentifier + name;
   int WatermarkFontSize = 30;
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xCord);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yCord);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetString (0,  name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, WatermarkFontSize);
   ObjectSetDouble (0,  name, OBJPROP_ANGLE, 0.0);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 5);
   ObjectSetString(0,  name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray);
  
}

void clsSND::FindLastResSup(void)
{
   //NORMAL SND
   this.sup_up_prev = 0;
   this.sup_dn_prev = 0;
   this.res_up_prev = 0;
   this.res_dn_prev = 0;
   for(int i = ArraySize(this.LevelList) - 1; i>= 0; i--)
   {
       if(this.LevelList[i].type == "Support" &&
          this.LevelList[i].lowPrice < this.sup_dn &&
          this.LevelList[i].isBreak == false
         )
       {
          this.sup_up_prev = this.LevelList[i].highPrice;
          this.sup_dn_prev = this.LevelList[i].lowPrice;
          break;
       }
   }
   for(int i = ArraySize(this.LevelList) - 1; i>= 0; i--)
   {
       if(this.LevelList[i].type == "Resistance" &&
          this.LevelList[i].highPrice > this.res_up &&
          this.LevelList[i].isBreak == false
         )
       {
          this.res_up_prev = this.LevelList[i].highPrice;
          this.res_dn_prev = this.LevelList[i].lowPrice;
          break;
       }
   }
   
   
   
}

void clsSND::CopyCLevel(CLevel &source[], CLevel &destination[])
{
   ArrayResize(destination,ArraySize(source));
   for (int i = 0; i < ArraySize(source)-1; i++)
   {
        destination[i] = source[i];
   }
}

void clsSND::CheckFreshLevel(int bar)
{
   //CLevel empty[];
   ArrayFree(this.FreshLevelList);
   this.CopyCLevel(this.LevelList,this.FreshLevelList);
   //ArrayCopy(this.FreshLevelList,this.LevelList);
   
   for(int i = ArraySize(this.FreshLevelList) - 1; i>= 0; i--)
   {
       if(this.FreshLevelList[i].isActive)
       {
           //int    cur_idx     = iBarShift(this.strSymbol,this.intPeriod,this.FreshLevelList[i].startDate);
           int    cur_idx     = intBarByDate(Times,FreshLevelList[i].startDate);
           int    base_dist   = this.FreshLevelList[i].SNDBaseDist;
           int    end_idx     = cur_idx >=  base_dist ? cur_idx - base_dist : 0;
           if(end_idx > 1)
           {
              if(this.FreshLevelList[i].type == "Support")
              {
                    double price_check = this.FreshLevelList[i].highPrice;
                    //int    right_lowest_idx   = iLowest(this.strSymbol,this.intPeriod,MODE_LOW,end_idx,bar);
                    int    right_lowest_idx   = intLowestIdx(Lows,end_idx,bar);
                    //double right_lowest_price = iLow(this.strSymbol,this.intPeriod,right_lowest_idx);
                    double right_lowest_price = Lows[right_lowest_idx];
                    
                    if(right_lowest_price < price_check)
                    {
                         this.FreshLevelList[i].isFresh = false;
                         this.FreshLevelList[i].isActive = false;
                    }
              }
              if(this.FreshLevelList[i].type == "Resistance")
              {
                    double price_check = this.FreshLevelList[i].lowPrice;
                    //int    right_highest_idx   = iHighest(this.strSymbol,this.intPeriod,MODE_HIGH,end_idx,bar);
                    int    right_highest_idx   = intHighestIdx(Highs,end_idx,bar);
                    //double right_highest_price = iHigh(this.strSymbol,this.intPeriod,right_highest_idx);
                    double right_highest_price = Highs[right_highest_idx];
                    
                    if(right_highest_price > price_check)
                    {
                         this.FreshLevelList[i].isFresh = false;
                         this.FreshLevelList[i].isActive = false;
                    }
              }
           }
       }
       
   }
   
   //GET NEAREST FRESH LEVEL
    this.res_up_fresh  = 0;
    this.res_dn_fresh  = 0;
    this.sup_up_fresh  = 0;
    this.sup_dn_fresh  = 0;
    this.sup_bar_fresh = -1;
    this.res_bar_fresh = -1;
    double lowestPrice  = DBL_MIN;
    double highestPrice = DBL_MAX;
   
   for(int i = 0; i < ArraySize(this.FreshLevelList); i++)
   {
      if(this.FreshLevelList[i].isActive)
      {
          //Print("Active Level Found");
          if(this.FreshLevelList[i].type == "Support")
          {
               //Print("Support Found");
               if(//this.LevelList[i].highPrice > iClose(this.strSymbol,this.intPeriod,cur_bar) ||
                  this.FreshLevelList[i].lowPrice < iLow(this.strSymbol,this.intPeriod,bar)
                 )
               {
                   //we need FreshLevelList the maximum
                   if(this.FreshLevelList[i].highPrice > lowestPrice)
                   {
                       this.sup_up_fresh = this.FreshLevelList[i].highPrice;
                       this.sup_dn_fresh = this.FreshLevelList[i].lowPrice;
                       //this.sup_bar_fresh = iBarShift(this.strSymbol,this.intPeriod,this.FreshLevelList[i].startDate);
                       this.sup_bar_fresh = intBarByDate(Times,this.FreshLevelList[i].startDate);
                       this.sup_start_time_fresh = this.FreshLevelList[i].startDate;
                       this.intLastFreshSupIdx = i;
                       lowestPrice = this.FreshLevelList[i].highPrice;
                       this.latest_fresh_sup_lvl = this.FreshLevelList[i];
                   }
               }
          }
          else
          {
                if(this.FreshLevelList[i].type == "Resistance")
                {
                     //Print("Resistance Found");
                     if(//this.LevelList[i].lowPrice < iClose(this.strSymbol,this.intPeriod,cur_bar) ||
                        //this.FreshLevelList[i].highPrice > iHigh(this.strSymbol,this.intPeriod,bar)
                        this.FreshLevelList[i].highPrice > Highs[bar]
                       )
                     {
                         //we need find the minimum
                         if(this.FreshLevelList[i].lowPrice < highestPrice)
                         {
                             //Print("Optimal Resistanec Found");
                             this.res_up_fresh = this.FreshLevelList[i].highPrice;
                             this.res_dn_fresh = this.FreshLevelList[i].lowPrice;
                             //this.res_bar_fresh = iBarShift(this.strSymbol,this.intPeriod,this.FreshLevelList[i].startDate);
                             this.res_bar_fresh = intBarByDate(Times,this.FreshLevelList[i].startDate);
                             this.res_start_time_fresh = this.FreshLevelList[i].startDate;
                             this.intLastFreshResIdx = i;
                             highestPrice = this.FreshLevelList[i].lowPrice;
                             this.latest_fresh_res_lvl = this.FreshLevelList[i];
                         }
                     }
                }
          }
      }
   }
}










