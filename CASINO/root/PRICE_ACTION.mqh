#include  "MASTER_INDI.mqh"
#include  "CANDLE_PATTERN.mqh"
extern bool OB_DrawZone = true;
//+------------------------------------------------------------------+
//|  PRICE ACTION SENTIMENT BASED ASSESSMENT                         |
//+------------------------------------------------------------------+

struct LiquidLevel
{
   double            highPrice;
   double            lowPrice;
   datetime          startDate;
   int               startidx;
   bool              isTested;
   int               type;
   
   LiquidLevel() : highPrice(0), lowPrice(0), startDate(0), startidx(-1), isTested(false), type(0) {}; 
};

class clsPriceAction : 
     public  clsMasterIndi
{
   public:
     
              clsPriceAction(string strInputSymbol, int intInputTF, bool ea_mode=false);
              ~clsPriceAction();
     void     Updater(datetime time,bool preloop=false);
     double   dblHighs[];
     double   dblLows[];
     double   dblOpens[];
     double   dblCloses[];
     datetime dtTimes[];
     //output
     int      intTrendViaCount;
     int      intTrendViaConsecutive;
     int      intTrendViaBody;
     int      intTrendViaCloseExtreme;
     int      intTrendViaBiggerBody;
     int      intTrendViaWick;
     bool     blMarketRanging;
     bool     blMarketRangingViaOverlapping;
     bool     blMarketRangingViaDoji;
     bool     blFinalMarketRanging;
     double   dblMACrossRatio;
     double   dblOverlappingCrossRatio;
     double   dblDojiCrossRatio;
     
     //test internal function
     bool     blIsDoji(int bar);
     bool     blBullishWick(int bar);
     bool     blBearishWick(int bar);
     bool     blFUCandle(int type, int bar);
     bool     blRealFUCandle(int type, int bar);
     bool     blAttemptedFUCandle(int type, int bar);
     bool     blPowerBullMove(int right_idx, int count);
     bool     blPowerBearMove(int right_idx, int count);
     int      intNextLiquidZoneIdx(int bar);
     void     GetLiquidZone();
     void     PlotZone();
     void     DeleteLevel(void);
     LiquidLevel OBLVLs[];
     bool     blNearSupport(void);
     bool     blNearResistance();
     
   
   protected:
     void     Oninit();
     void     StoreOHLC(int bar);
     //PART 1 : NORMAL NUMBER OF BULL BEAR COUNTER
     void     BullBearCounter();
     //PART 2 : CONSECUTIVE COUNTER
     int      intConsecutiveEnd(int type, int start_bar);   //if to change consecutive candle type, eg body size to allow for consecutive count, edit here
     void     ConsecutiveMomentumCounter();
     //PART 3 : BODY COUNTER
     void     BodyCounter();
     //PART 4 : PRICE CLOSE AT EXTREME COUNTER
     void     CloseExtremeCounter();
     //PART 5 : BODY GETTING BIGGER
     int      intBiggerEnd(int type, int start_bar); //if to change a bigger end candle type, edit here
     void     BiggerBodyCounter();
     //PART 6 : WICK COUNTER
     void     WickCounter();
     //PART 7 : FIND RANGE OR TREND USING EMA
     void     FindRangeTrend();
     //PART 8 : FIND RANGE OR TREND USING OVERLAPPING CANDLE
     void     FindOverlappingRangeTrend();
     //PART 9 : FIND RANGE OR TREND USING DOJI
     void     FindDojiRangingTrend();
     
     //DRAWING
     void     DrawRectangle(double price1, datetime time1, double price2, datetime time2, int type=1);
   
   private:
     string   strIdentifier;
     bool     blEAMode;
     int      intConsecutiveThreshold;
     int      intHighestIdx;
     int      intLowestIdx;
     int      intMALookBack;
     double   dblMARangingCrossThreshold;
     double   dblOverlappingRangingThreshold;
     double   dblDojiRangingThreshold;
     color    res_color;
     color    sup_color;
     

};

clsPriceAction::clsPriceAction(string strInputSymbol, int intInputTF, bool ea_mode=false):
        clsMasterIndi(strInputSymbol,intInputTF)
{
  Print("Price Action Constructor at Child ",strInputSymbol);
  blEAMode = ea_mode;
  this.Oninit();
}

clsPriceAction::~clsPriceAction(void)
{
    DeleteLevel();
}

void clsPriceAction::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"BOXKIE"+(string)this.intPeriod;
    intMaxStore = 200; 
    intConsecutiveThreshold = 3; //EDITRABLE MIN CONSECUTIVE COUNT
    intMALookBack = 20;
    dblMARangingCrossThreshold = 0;
    dblOverlappingRangingThreshold = 0.3;
    dblDojiRangingThreshold = 0.3;
    res_color = clrRed;
    sup_color = clrBlue;
    if(blEAMode) Preloop();
}

void clsPriceAction::Updater(datetime time,bool preloop=false)
{
    int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
    if(!preloop)Print("Timeframe ",intPeriod," start storing at ",latest_bar," with time of ",TimeCurrent());
    StoreOHLC(latest_bar);
    BullBearCounter();
    ConsecutiveMomentumCounter();
    BodyCounter();
    CloseExtremeCounter();
    BiggerBodyCounter();
    WickCounter();
    FindRangeTrend();
    FindOverlappingRangeTrend();
    FindDojiRangingTrend();
    blFinalMarketRanging = blMarketRanging && blMarketRangingViaOverlapping && blMarketRangingViaDoji;
    
    if(latest_bar == 0)GetLiquidZone();
    if(OB_DrawZone && latest_bar == 0) PlotZone();
}

void clsPriceAction::StoreOHLC(int bar)
{
    for(int i = bar + intMaxStore - 1; i >= bar ; i--)
    {
         double open   = iOpen(strSymbol,intPeriod,i);
         double high   = iHigh(strSymbol,intPeriod,i);
         double low    = iLow(strSymbol,intPeriod,i);
         double close  = iClose(strSymbol,intPeriod,i);
         datetime time = iTime(strSymbol,intPeriod,i);
         
         StoreArray(open, dblOpens,intMaxStore,true);
         StoreArray(high, dblHighs,intMaxStore,true);
         StoreArray(low,  dblLows,intMaxStore,true);
         StoreArray(close,dblCloses,intMaxStore,true);
         StoreArray(time, dtTimes,intMaxStore,true);
    }
    intHighestIdx = iHighest(strSymbol,intPeriod,MODE_HIGH,intMaxStore,bar);
    intLowestIdx  = iLowest (strSymbol,intPeriod,MODE_LOW,intMaxStore,bar);
    
}

void clsPriceAction::BullBearCounter(void)
{
    if(ArraySize(dblOpens) != intMaxStore) return;
    int bull_count = 0;
    int bear_count = 0;
    for(int i = 0; i < intMaxStore; i++)
    {
          if(dblCloses[i] > dblOpens[i]) bull_count++;
          if(dblCloses[i] < dblOpens[i]) bear_count++;
    }
    if(bull_count > bear_count) intTrendViaCount = 1;
    if(bear_count > bull_count) intTrendViaCount = 2;
}

int clsPriceAction::intConsecutiveEnd(int type, int start_bar)
{
    //the function of this is to find the next new bar after each consecutive up/down
    //if to change consecutive candle type, eg body size to allow for consecutive count, edit here
    int out = start_bar;
    if(type == 1)
    {
        for(int i = start_bar; i < intMaxStore; i++)
        {
             out = i;
             double body  = MathAbs(dblCloses[i] - dblOpens[i]);
             double range = MathAbs(dblHighs[i] - dblLows[i]);
             if(dblCloses[i] < dblOpens[i] || (range != 0 && body / range <= 0.1)) 
             {  
                 break; // we return straight
             }
             
        }
    }
    if(type == 2)
    {
        for(int i = start_bar; i < intMaxStore; i++)
        {
             out = i;
             double body  = MathAbs(dblCloses[i] - dblOpens[i]);
             double range = MathAbs(dblHighs[i] - dblLows[i]);
             if(dblCloses[i] > dblOpens[i] || (range != 0 && body / range <= 0.1)) 
             {  
                 break; // we return straight
             }
             
        }
    }
    out = out == 0 ? 1 : out;
    return(out);
}

void clsPriceAction::ConsecutiveMomentumCounter()
{
    
    int cur_phase = 0;
    int bull_count = 0;
    int bear_count = 0;
    //we count for bull first, don't mix
    for(int i = 0; i < intMaxStore - 1; i++)
    {
        int end_idx = intConsecutiveEnd(1,i);
        if(end_idx - i >= intConsecutiveThreshold) 
        {
           bull_count++;
        }
        i = end_idx;
        
    }
    
    //then we count for bear, don't mix
    for(int i = 0; i < intMaxStore - 1; i++)
    {
        int end_idx = intConsecutiveEnd(2,i);
        if(end_idx - i >= intConsecutiveThreshold) 
        {
            bear_count++;
        }
        i = end_idx;
        
    }
    if(bull_count > bear_count) intTrendViaConsecutive = 1;
    if(bear_count > bull_count) intTrendViaConsecutive = 2;
}

void clsPriceAction::BodyCounter(void)
{
    double bull_body_sum = 0;
    double bull_candle_count = 0;
    
    double bear_body_sum = 0;
    double bear_candle_count = 0;
    
    for(int i = 0; i < intMaxStore; i++)
    {
         if(dblCloses[i] > dblOpens[i])
         {
             //bullish candle
             bull_body_sum += MathAbs(dblCloses[i] - dblOpens[i]);
             bull_candle_count++;
         }
         if(dblCloses[i] < dblOpens[i])
         {
             //bearish candle
             bear_body_sum += MathAbs(dblCloses[i] - dblOpens[i]);
             bear_candle_count++;
         }  
    }
    
    double bull_mean_body = bull_candle_count != 0 ? bull_body_sum / bull_candle_count : 0;
    double bear_mean_body = bear_candle_count != 0 ? bear_body_sum / bear_candle_count : 0;
    
    if(bull_mean_body > bear_mean_body) intTrendViaBody = 1;
    if(bull_mean_body < bear_mean_body) intTrendViaBody = 2;
}

void clsPriceAction::CloseExtremeCounter(void)
{
     int bull_count = 0;
     int bear_count = 0;
     
     for(int i = 0; i < intMaxStore; i++)
     {
          double body  = MathAbs(dblCloses[i] - dblOpens[i]);
          double range = MathAbs(dblHighs[i]  - dblLows[i]);
          double fragment = range / 10;
          
          if(dblCloses[i] > dblOpens[i])
          {
             //bullish candle
             if(dblHighs[i] - dblCloses[i] <= fragment) bull_count++;   
          }
          if(dblCloses[i] < dblOpens[i])
          {
             //bearish candle
             if(dblCloses[i] - dblLows[i] <= fragment) bear_count++;   
          }
     }
     if(bull_count > bear_count) intTrendViaCloseExtreme = 1;
     if(bear_count > bull_count) intTrendViaCloseExtreme = 2;
}

int clsPriceAction::intBiggerEnd(int type, int start_bar)
{
     //the function of this is to find the next new bar after each consecutive bigger candle
    //if to change consecutive size changes type, edit here
    int out = start_bar;
    if(type == 1)
    {
        for(int i = start_bar; i < intMaxStore - 1; i++)
        {
             out = i;
             double body  = MathAbs(dblCloses[i] - dblOpens[i]);
             double body_prev  = MathAbs(dblCloses[i+1] - dblOpens[i+1]);
             double range = MathAbs(dblHighs[i] - dblLows[i]);
             if(dblCloses[i] < dblOpens[i] || body < body_prev) 
             {  
                 break; // we return straight
             }
             
        }
    }
    if(type == 2)
    {
        for(int i = start_bar; i < intMaxStore - 1; i++)
        {
             out = i;
             double body  = MathAbs(dblCloses[i] - dblOpens[i]);
             double body_prev  = MathAbs(dblCloses[i+1] - dblOpens[i+1]);
             double range = MathAbs(dblHighs[i] - dblLows[i]);
             if(dblCloses[i] > dblOpens[i] ||  body < body_prev) 
             {  
                 break; // we return straight
             }
             
        }
    }
    out = out == 0 ? 1 : out;
    return(out);
}

void clsPriceAction::BiggerBodyCounter()
{
    int bull_count = 0;
    int bear_count = 0;
    //we count for bull first, don't mix
    for(int i = 0; i < intMaxStore - 1; i++)
    {
        int end_idx = intBiggerEnd(1,i);
        if(end_idx - i > 1) 
        {
           bull_count++;
        }
        i = end_idx;
        
    }
    
    //then we count for bear, don't mix
    for(int i = 0; i < intMaxStore - 1; i++)
    {
        int end_idx = intBiggerEnd(2,i);
        if(end_idx - i > 1) 
        {
            bear_count++;
        }
        i = end_idx;
        
    }
    if(bull_count > bear_count) intTrendViaBiggerBody = 1;
    if(bear_count > bull_count) intTrendViaBiggerBody = 2;
}

void clsPriceAction::WickCounter(void)
{
    int bull_count = 0;
    int bear_count = 0;
    for(int i = 0; i < intMaxStore; i++)
    {
        double up_body = MathMax(dblCloses[i],dblOpens[i]);
        double dn_body = MathMin(dblCloses[i],dblOpens[i]);
        double up_wick = dblHighs[i] - up_body;
        double dn_wick = dn_body - dblLows[i];
        double wick    = MathMax(up_wick,dn_wick);
        
        if(dblCloses[i] > dblOpens[i])
        {
            if(wick == dn_wick) bull_count++;
        }
        if(dblCloses[i] < dblOpens[i])
        {
            if(wick == up_wick) bear_count++;
        }
    }
    if(bull_count > bear_count) intTrendViaWick = 1;
    if(bear_count > bull_count) intTrendViaWick = 2;
}

void clsPriceAction::FindRangeTrend()
{
    if(intMALookBack > intMaxStore) return;
    blMarketRanging = false;
    bool latest_bar_range = false;
    
    int cross_count = 0;
    for(int i = intMALookBack - 1; i >= 0; i--)
    {
        double ema = iMA(strSymbol,intPeriod,20,0,MODE_EMA,PRICE_CLOSE,i);
        if(ema < dblHighs[i] && ema > dblLows[i])
        {
            cross_count++;
            if(i == 0) latest_bar_range = true;
        }
    }
    double cross_ratio = (double)cross_count/(double)intMALookBack;
    dblMACrossRatio = cross_ratio;
    
    if(cross_ratio > dblMARangingCrossThreshold) blMarketRanging = true;
    if(latest_bar_range) blMarketRanging = true;
}

void clsPriceAction::FindOverlappingRangeTrend()
{
    if(intMALookBack > intMaxStore) return;
    blMarketRangingViaOverlapping = false;
    bool latest_bar_range = false;
    int range_count = 0;
    int cross_count = 0;
    for(int i = intMaxStore - 2; i >= 0; i--)
    {
         if
         (
              (dblHighs[i] > dblHighs[i+1] && dblLows[i] > dblLows[i+1]) ||
              (dblHighs[i] < dblHighs[i+1] && dblLows[i] < dblLows[i+1])
         )
         {
             //this is trending
         }
         else
         {
               range_count++;
         }
    }
    dblOverlappingCrossRatio = ((double)range_count / (double)intMaxStore);
    if( dblOverlappingCrossRatio <= dblOverlappingRangingThreshold)
    {
        blMarketRangingViaOverlapping = true;
    }
    
}

void clsPriceAction::FindDojiRangingTrend()
{
    int range_count = 0;
    double doji_body_percent    = 5;
    double shadow_equal_percent = 100;
    for(int i = intMaxStore - 1; i >= 0; i--)
    {
         if(blIsDoji(i)) range_count++;
    }
    dblDojiCrossRatio = ((double)range_count / (double)intMaxStore);
    if(  dblDojiCrossRatio != 0 && (dblDojiCrossRatio >= 0.04) ) blMarketRangingViaDoji = true;
}

bool clsPriceAction::blIsDoji(int bar)
{ 
      double doji_body_percent    = 15;
      double shadow_equal_percent = 100;
      double body_high = MathMax(dblOpens[bar],dblCloses[bar]);
      double body_low  = MathMin(dblOpens[bar],dblCloses[bar]);
      double body_size = body_high - body_low;
      double up_shadow = dblHighs[bar] - body_high;
      double dn_shadow = body_low    - dblLows[bar];
      double range     = dblHighs[bar] - dblLows[bar];
      bool   doji_body = range != 0 && body_size <= range * doji_body_percent / 100;
      bool   equal_shadow = false;
      if(up_shadow != 0 && dn_shadow != 0)
      {
           
           if(up_shadow == dn_shadow) equal_shadow = true;
           else
           {
                if( 
                     (MathAbs(up_shadow - dn_shadow) / dn_shadow * 100) < shadow_equal_percent && 
                     (MathAbs(dn_shadow - up_shadow) / up_shadow * 100) < shadow_equal_percent
                  )
                  {
                       equal_shadow = true;
                  }
           }
           
      }
      bool doji = doji_body && equal_shadow;
      return(doji);
}

bool clsPriceAction::blBullishWick(int bar)
{ 
      double wick_threshold = 0.4;
      double body_high = MathMax(dblOpens[bar],dblCloses[bar]);
      double body_low  = MathMin(dblOpens[bar],dblCloses[bar]);
      double body_size = body_high - body_low;
      double up_shadow = dblHighs[bar] - body_high;
      double dn_shadow = body_low    - dblLows[bar];
      double range     = dblHighs[bar] - dblLows[bar];
      bool   equal_shadow = false;
      if(dn_shadow != 0)
      {
          //if(dn_shadow / range >=  0.5) return(true);
          if(dn_shadow >= up_shadow && dn_shadow / range >=  0.2) return(true);
      }
      return(false);
}

bool clsPriceAction::blBearishWick(int bar)
{ 
      double wick_threshold = 0.4;
      double body_high = MathMax(dblOpens[bar],dblCloses[bar]);
      double body_low  = MathMin(dblOpens[bar],dblCloses[bar]);
      double body_size = body_high - body_low;
      double up_shadow = dblHighs[bar] - body_high;
      double dn_shadow = body_low    - dblLows[bar];
      double range     = dblHighs[bar] - dblLows[bar];
      bool   equal_shadow = false;
      if(up_shadow != 0)
      {
          //if(up_shadow / range >=  0.5) return(true);
          if(up_shadow >= dn_shadow && up_shadow / range >=  0.2) return(true);
      }
      return(false);
}

bool clsPriceAction::blAttemptedFUCandle(int type, int bar)
{
     int look_back = 1;
     int prev_bar = bar + look_back;
     double body_high       = MathMax(dblOpens[bar],dblCloses[bar]);
     double body_low        = MathMin(dblOpens[bar],dblCloses[bar]);
     double body_size       = body_high - body_low;
     double up_shadow       = dblHighs[bar] - body_high;
     double dn_shadow       = body_low    - dblLows[bar];
     double range           = dblHighs[bar] - dblLows[bar];
     double body_high_prev  = MathMax(dblOpens[prev_bar],dblCloses[prev_bar]);
     double body_low_prev   = MathMin(dblOpens[prev_bar],dblCloses[prev_bar]);
     double body_size_prev  = body_high_prev - body_low_prev;
     double up_shadow_prev  = dblHighs[prev_bar] - body_high_prev;
     double dn_shadow_prev  = body_low_prev    - dblLows[prev_bar];
     double range_prev      = dblHighs[prev_bar] - dblLows[prev_bar];
     
     if(type == 1)
     {
           if( 
                //prev bar is bear doji
                dblCloses[prev_bar] < dblOpens[prev_bar]
                && up_shadow_prev / range_prev >= 0.3
                && up_shadow_prev > dn_shadow_prev
                //cur bar is bull doji
                && dblCloses[bar] > dblOpens[prev_bar]
                && dn_shadow     / range_prev  >= 0.3
                && dn_shadow     > up_shadow
                && dblLows[bar]  < dblLows[prev_bar]
             )
           {
               return(true);
           }
     }
     
     if(type == 2)
     {
           if( 
                //prev bar is bull doji
                dblCloses[prev_bar] > dblOpens[prev_bar]
                && dn_shadow_prev / range_prev >= 0.3
                && dn_shadow_prev > up_shadow_prev
                //cur bar is bear doji
                && dblCloses[bar] < dblOpens[prev_bar]
                && up_shadow     / range_prev  >= 0.3
                && up_shadow     > dn_shadow
                && dblHighs[bar] > dblHighs[prev_bar]
             )
           {
               return(true);
           }
     }
     return(false);
}


bool clsPriceAction::blRealFUCandle(int type, int bar)
{
     int look_back = 1;
     int prev_bar = bar + look_back;
     double body_high  = MathMax(dblOpens[bar],dblCloses[bar]);
     double body_low   = MathMin(dblOpens[bar],dblCloses[bar]);
     double body_size  = body_high - body_low;
     double up_shadow  = dblHighs[bar] - body_high;
     double dn_shadow  = body_low    - dblLows[bar];
     double range      = dblHighs[bar] - dblLows[bar];
     double range_prev = dblHighs[prev_bar] - dblLows[prev_bar];
     
     if(type == 1)
     {
         if(
              dblCloses[bar] > dblOpens[bar]
              && dn_shadow / range >= 0.4
              && dblHighs[bar] > dblHighs[prev_bar]
              && dblLows[bar]  < dblLows[prev_bar]
              && range > range_prev
           )
         {
             return(true);
         }
     }
     
     if(type == 2)
     {
         if(
              dblCloses[bar] < dblOpens[bar]
              && up_shadow / range >= 0.4
              && dblLows[bar] < dblLows[prev_bar]
              && dblHighs[bar] > dblHighs[prev_bar]
              && range > range_prev
           )
         {
             return(true);
         }
     }
     return(false);
}

bool clsPriceAction::blFUCandle(int type, int bar)
{
     if(blRealFUCandle(type,bar) || blAttemptedFUCandle(type,bar))
     {
        Print("Type is ",type);
        Print("At timeframe of ",intPeriod);
        Print("Bar is ",bar);
        Print("Close price is ",dblCloses[bar]);
        Print("Real FU is ",blRealFUCandle(type,bar));
        Print("Attempted FU is ",blAttemptedFUCandle(type,bar));
        
        return(true);
     }
     return(false);
}

void clsPriceAction::GetLiquidZone()
{
    //+------------------------------------------------------------------+
    //| PART 1 : GET ALL LEVELS                                          |
    //+------------------------------------------------------------------+
    
    ArrayFree(OBLVLs);
    for(int i = 0; i < ArraySize(dblCloses); i++)
    {
          //Print("Next index is ",i);
          i = intNextLiquidZoneIdx(i);
          
    }
    
    //+-----------------------------------------------------------------------+
    //| PART 2 : Loop to sort in ascending to descending sequnce : 0 is lowest|
    //+-----------------------------------------------------------------------+
     
    for (int i = 0; i < ArraySize(OBLVLs); i++) 
    {
         for (int j = i + 1; j < ArraySize(OBLVLs); j++)
         {
             if(OBLVLs[i].lowPrice > OBLVLs[j].lowPrice)
             {
                 LiquidLevel tmp;
                 tmp = OBLVLs[i];
                 OBLVLs[i] = OBLVLs[j];
                 OBLVLs[j] = tmp;
             }

         }
     }
     Print("Post Sort level number is ",ArraySize(OBLVLs));
     
     //+------------------------------------------------------------------+
     //|  PART 3 : Remove Tested Line                                     |
     //+------------------------------------------------------------------+
     /*
     int chk_idx = 3;
     for (int i = 0; i < ArraySize(OBLVLs); i++)
     {
          if(OBLVLs[i].startidx < chk_idx) continue;
          for(int j = OBLVLs[i].startidx - chk_idx; j >= 0; j--)
          {
             if(OBLVLs[i].type == 1)
             {
                  if(
                       dblCloses[j] >= OBLVLs[i].lowPrice &&
                       dblLows[j]   <= OBLVLs[i].highPrice &&
                       dblCloses[j] >= dblOpens[j]  
                    )
                  {
                       OBLVLs[i].isTested = true;
                       break;
                  }
             }
             if(OBLVLs[i].type == 2)
             {
                  if(
                       dblCloses[j] <= OBLVLs[i].highPrice &&
                       dblHighs[j]  >= OBLVLs[i].lowPrice &&
                       dblCloses[j] <= dblOpens[j]  
                    )
                  {
                       OBLVLs[i].isTested = true;
                       break;
                  }
             }
          }
     }
     */
     
     //+------------------------------------------------------------------+
     //|  PART 4 : Make the intersecting levels into single level         |
     //+------------------------------------------------------------------+
     
     LiquidLevel merge_list[];
     for (int i = 0; i < ArraySize(OBLVLs); i++)
     {
          
          LiquidLevel tmp;
          if(
               i < ArraySize(OBLVLs) - 1 &&
               OBLVLs[i].highPrice > OBLVLs[i+1].lowPrice &&
               OBLVLs[i].type     == OBLVLs[i+1].type
            )
          {
               tmp.highPrice = MathMax(OBLVLs[i].highPrice,OBLVLs[i+1].highPrice);
               tmp.lowPrice  = MathMin(OBLVLs[i].lowPrice,OBLVLs[i+1].lowPrice);
               tmp.startDate = MathMax(OBLVLs[i].startDate,OBLVLs[i+1].startDate);
               tmp.type      = OBLVLs[i].type;
               tmp.isTested  = OBLVLs[i].isTested;
               i = i+ 1;
          }
          else
          {
               tmp = OBLVLs[i];
          }
          int ori_size = ArraySize(merge_list);
          ArrayResize(merge_list,ori_size+1);
          merge_list[ori_size] = tmp;
     }
     
     //copy the merge list to ori array list
     ArrayFree(OBLVLs);
     ArrayResize(OBLVLs,ArraySize(merge_list));
     for(int i = 0; i < ArraySize(merge_list); i++)
     {
         OBLVLs[i] = merge_list[i];
     }
     Print("Post Merge level number is ",ArraySize(OBLVLs));
     
}

int clsPriceAction::intNextLiquidZoneIdx(int bar)
{ 
     int power_count         = 3;
     //Print("Hi");
     clsCandlePattern CANDLE(bar,strSymbol,intPeriod);
     //if(CANDLE.C_BullishEngulfing() || CANDLE.C_BearishEngulfing()) power_count = 1;
     
     int end_count_idx       = bar + power_count;
     if(ArraySize(dblCloses) <= end_count_idx) return(end_count_idx);
     
     if(blPowerBullMove(bar,power_count))// || CANDLE.C_BullishEngulfing())
     {
          //Print("Hi a");
          
          LiquidLevel new_lvl;
          for(int i = end_count_idx; i < ArraySize(dblCloses); i++)
          {
               //Print("First End count idx is ",end_count_idx);
               if(!blPowerBullMove(i-(power_count-1),power_count))// || !CANDLE.C_BullishEngulfing())  // a measure to make sure we loop through all bullish sequence
               {
                  double body_high = MathMax(dblCloses[i],dblOpens[i]);
                  double body_low  = MathMin(dblCloses[i],dblOpens[i]);
                  new_lvl.highPrice = new_lvl.highPrice == 0 ? body_high : MathMax(body_high,new_lvl.highPrice);
                  new_lvl.lowPrice  = new_lvl.lowPrice == 0  ? body_low  : MathMin(body_low,new_lvl.lowPrice);
                  new_lvl.startDate = dtTimes[i];
                  new_lvl.type      = 1;
                  new_lvl.startidx  = i;
                  //we stop when meet any existing bear candle, our aim is to look for bull force
                  if(dblCloses[i] < dblOpens[i])
                  //if(new_lvl.highPrice != 0)// && (dblCloses[i] < dblOpens[i] || blIsDoji(i)))
                  {
                        //store into array
                        int ori_size      = ArraySize(OBLVLs);
                        ArrayResize(OBLVLs,ori_size+1);
                        OBLVLs[ori_size] = new_lvl; 
                        return(end_count_idx);
                        break;
                  }
                  //else we just take the highest
                  
                    
               }
          }
     }
     
     
     if(blPowerBearMove(bar,power_count))// || CANDLE.C_BearishEngulfing())
     {
          LiquidLevel new_lvl;
          for(int i = end_count_idx; i < ArraySize(dblCloses); i++)
          {
               if(!blPowerBearMove(i-(power_count-1),power_count))// || !CANDLE.C_BearishEngulfing())  // a measure to make sure we loop through all bullish sequence
               {
                  double body_high = MathMax(dblCloses[i],dblOpens[i]);
                  double body_low  = MathMin(dblCloses[i],dblOpens[i]);
                  new_lvl.highPrice = new_lvl.highPrice == 0 ? body_high : MathMax(body_high,new_lvl.highPrice);
                  new_lvl.lowPrice  = new_lvl.lowPrice == 0  ? body_low  : MathMin(body_low,new_lvl.lowPrice);
                  new_lvl.startDate = dtTimes[i];
                  new_lvl.type      = 2;
                  new_lvl.startidx  = i;
                  //we stop when meet any existing bear candle, our aim is to look for bull force
                  //if(new_lvl.highPrice != 0 && (dblCloses[i] > dblOpens[i] || blIsDoji(i)))
                  if(dblCloses[i] > dblOpens[i])
                  {
                        //store into array
                        if(bar == 42)
                        { 
                           Print("Hey");
                           Print("Currnet Level High is ",new_lvl.highPrice);
                           Print("Currnet Level Low is " ,new_lvl.lowPrice);
                        } 
                        int ori_size      = ArraySize(OBLVLs);
                        ArrayResize(OBLVLs,ori_size+1);
                        OBLVLs[ori_size] = new_lvl;
                        return(end_count_idx);
                        break;
                  }
                  
                  //else we just take the highest
                  
                  
               }
          }
     }
     return(bar);
}

bool clsPriceAction::blPowerBullMove(int right_idx, int count)
{
     int end_count_idx       = right_idx + count;
     if(ArraySize(dblCloses) <= end_count_idx) return(false);
     int power_count = 0;
     for(int i = right_idx; i < right_idx + count ; i++)
     {
          double body  = MathAbs(dblCloses[i] - dblOpens[i]);
          double range = dblHighs[i] - dblLows[i];
          if(  
               //dblCloses[i] > dblOpens[i] && dblCloses[i] > dblCloses[i+1] //&&
               dblCloses[i] > dblCloses[i+1]
               //body / range >= 0.3
            )
          {
              //bull candle and higher close
              power_count++;
          }
     }
     if(power_count >= count) return(true);
     return(false);
}

bool clsPriceAction::blPowerBearMove(int right_idx, int count)
{
     int end_count_idx       = right_idx + count;
     if(ArraySize(dblCloses) <= end_count_idx) return(false);
     int power_count = 0;
     for(int i = right_idx; i < right_idx + count ; i++)
     {
          double body  = MathAbs(dblCloses[i] - dblOpens[i]);
          double range = dblHighs[i] - dblLows[i];
          if(
               //dblCloses[i] < dblOpens[i] && dblCloses[i] < dblCloses[i+1] //&&
               dblCloses[i] < dblCloses[i+1]
               //body / range >= 0.3
            )
          {
              //bull candle and higher close
              power_count++;
          }
     }
     if(power_count >= count) return(true);
     return(false);
}

bool clsPriceAction::blNearSupport(void)
{
    double bid = MarketInfo(strSymbol,MODE_BID);
    double buffer = 5;
    for(int i = 0; i < ArraySize(OBLVLs); i++)
    {
         if(OBLVLs[i].type == 1 && OBLVLs[i].highPrice != 0 && OBLVLs[i].lowPrice != 0)
         {
            if(bid > OBLVLs[i].lowPrice && bid < OBLVLs[i].highPrice)
            {
               return(true);
            }
            if(OBLVLs[i].lowPrice - bid  <= buffer * pips(strSymbol))
            {
               return(true);
            }
            if(bid - OBLVLs[i].highPrice <= buffer * pips(strSymbol) && bid - OBLVLs[i].highPrice > 0)
            {
               return(true);
            }
         }
    }
    return(false);
}

bool clsPriceAction::blNearResistance(void)
{
    double bid = MarketInfo(strSymbol,MODE_BID);
    double buffer = 5;
    for(int i = 0; i < ArraySize(OBLVLs); i++)
    {
         if(OBLVLs[i].type == 2 && OBLVLs[i].highPrice != 0 && OBLVLs[i].lowPrice != 0)
         {
            if(bid > OBLVLs[i].lowPrice && bid < OBLVLs[i].highPrice)
            {
               return(true);
            }
            if(OBLVLs[i].lowPrice - bid  <= buffer * pips(strSymbol)) return(true);
            if(bid - OBLVLs[i].highPrice <= buffer * pips(strSymbol) && bid - OBLVLs[i].highPrice > 0) return(true);
         }
    }
    return(false);
}


void clsPriceAction::PlotZone()
{
    if(strSymbol != ChartSymbol()) return;
    DeleteLevel();
    for(int i = 0; i < ArraySize(OBLVLs); i++)
    {
         if(!OBLVLs[i].isTested)
         {
              DrawRectangle(OBLVLs[i].highPrice, OBLVLs[i].startDate, OBLVLs[i].lowPrice, TimeCurrent(), OBLVLs[i].type);
              if(i == 3)
              {
                  Print("High price should plot is ",OBLVLs[i].highPrice);
                  Print("Low price should plot is ",OBLVLs[i].lowPrice);
              }
         }
    }
}

void clsPriceAction::DrawRectangle(double price1, datetime time1, double price2, datetime time2, int type=1)
{
   
   string name = this.strIdentifier +"-OBLEVEL" + "-" + (string)type + "-" + DoubleToString(price1);
   color clr = (type == 1 ? this.sup_color : this.res_color);
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

void clsPriceAction::DeleteLevel(void)
{
   //Print("Prepare Delete");
   for (int i=ObjectsTotal()-1; i >= 0; i--) 
   {
      string obj_name = ObjectName(i); 
      string level_to_delete = this.strIdentifier +"-OBLEVEL";
      //string line_to_delete  = this.strIdentifier +" Round Number";
      if(StringFind(obj_name,level_to_delete)>=0)
      {
          //Print("Deleting ",obj_name);
          ObjectDelete(0,obj_name);
      }
   }
   ChartRedraw();
}
    