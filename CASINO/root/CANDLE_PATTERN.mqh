#include  "MASTER_INDI.mqh"

class clsCandlePattern : 
     public  clsMasterIndi
{
   public:
                      clsCandlePattern(int bar, string strInputSymbol, int intInputTF);
                      ~clsCandlePattern();
      //void            Updater(datetime time, bool preloop=false);
      bool            C_HammerBullish();
      bool            C_ShootingBearish();
      bool            C_PinBarBearish();
      bool            C_PinBarBullish();
      bool            C_BullishEngulfing();
      bool            C_BearishEngulfing();
      int             Pattern_BreakExtremeEngulf(); //1 bull -1 bear
      double          ema_body(int bar);
      double          ema_range(int bar);
      int             intBar;
      bool            blIsGreenCandle(int bar);
      int             C_Len; // ema depth for bodyAvg
      double          C_ShadowPercent; // size of shadows
      double          C_ShadowEqualsPercent;
      double          C_DojiBodyPercent;
      double          C_Factor; // shows the number of times the shadow dominates the candlestick body
      
      double          C_BodyHi;// = max(close, open)
      double          C_BodyLo;// = min(close, open)
      double          C_Body;// = C_BodyHi - C_BodyLo
      double          C_BodyAvg;// = ema(C_Body, C_Len)
      bool            C_SmallBody;//= C_Body < C_BodyAvg
      bool            C_LongBody;// = C_Body > C_BodyAvg
      double          C_UpShadow;// = high - C_BodyHi
      double          C_DnShadow;// = C_BodyLo - low
      bool            C_HasUpShadow;// = C_UpShadow > C_ShadowPercent / 100 * C_Body
      bool            C_HasDnShadow;// = C_DnShadow > C_ShadowPercent / 100 * C_Body
      bool            C_WhiteBody;// = open < close
      bool            C_BlackBody;// = open > close
      double          C_Range;// = high-low
      double          C_RangeAvg;
      bool            C_BigRange;
      bool            C_SmallRange;
      bool            C_IsInsideBar;// = C_BodyHi[1] > C_BodyHi and C_BodyLo[1] < C_BodyLo
      double          C_BodyMiddle;// = C_Body / 2 + C_BodyLo
      bool            C_ShadowEquals;// = C_UpShadow == C_DnShadow or (abs(C_UpShadow - C_DnShadow) / C_DnShadow * 100) < C_ShadowEqualsPercent and (abs(C_DnShadow - C_UpShadow) / C_UpShadow * 100) < C_ShadowEqualsPercent
      bool            C_IsDojiBody;// = C_Range > 0 and C_Body <= C_Range * C_DojiBodyPercent / 100
      bool            C_Doji;// = C_IsDojiBody and C_ShadowEquals
      bool            blBearishPattern();
      bool            blBullishPattern();
      
   protected:
      void            Oninit();
      
   private:
      //INDIVIDUALIZED PARAMETERS FOR DIFFERENT INDICATOR
      //ARRAY LIST
      bool            blCheckShadowEqual();
      
};


clsCandlePattern::clsCandlePattern(int bar, string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
{
    this.intBar = bar;
    this.Oninit();
}

clsCandlePattern::~clsCandlePattern(){}

bool clsCandlePattern::blBullishPattern()
{
    if(C_HammerBullish() || C_PinBarBullish() || C_BullishEngulfing()) return(true);
    return(false);
}

bool clsCandlePattern::blBearishPattern()
{
    if(C_ShootingBearish() || C_PinBarBearish() || C_BearishEngulfing()) return(true);
    return(false);
}

double clsCandlePattern::ema_body(int bar)
{
      double body_sum = 0;
      for(int i = intBar; i <= intBar + bar; i++)
      {
            double BodyHi = MathMax(iClose(this.strSymbol,this.intPeriod,i),iOpen(this.strSymbol,this.intPeriod,i));
            double BodyLo = MathMin(iClose(this.strSymbol,this.intPeriod,i),iOpen(this.strSymbol,this.intPeriod,i));
            body_sum += BodyHi - BodyLo;
      }
      return(body_sum/bar);
}

double clsCandlePattern::ema_range(int bar)
{
      double range_sum = 0;
      for(int i = intBar; i <= intBar + bar; i++)
      {
            double range = iHigh(this.strSymbol,this.intPeriod,this.intBar) - iLow(this.strSymbol,this.intPeriod,this.intBar);
            range_sum += range;
      }
      return(range_sum/bar);
}

void clsCandlePattern::Oninit(void)
{
      //Print("Initialzing bar ",this.intBar);
    //we loop basic and important fundamenta parameter
      this.C_Len = 14; // ema depth for bodyAvg
      this.C_ShadowPercent = 5.0; // size of shadows
      this.C_ShadowEqualsPercent = 100.0;
      this.C_DojiBodyPercent = 5.0;
      this.C_Factor = 2.0; // shows the number of times the shadow dominates the candlestick body
      
      this.C_BodyHi       = MathMax(iClose(this.strSymbol,this.intPeriod,this.intBar),iOpen(this.strSymbol,this.intPeriod,this.intBar));
      this.C_BodyLo       = MathMin(iClose(this.strSymbol,this.intPeriod,this.intBar),iOpen(this.strSymbol,this.intPeriod,this.intBar));
      this.C_Body         = this.C_BodyHi - this.C_BodyLo;
      this.C_BodyAvg      = this.ema_body(this.C_Len);
      this.C_SmallBody    = C_Body < C_BodyAvg;
      this.C_LongBody     = C_Body > C_BodyAvg;
      this.C_UpShadow     = iHigh(this.strSymbol,this.intPeriod,this.intBar) - C_BodyHi;
      this.C_DnShadow     = C_BodyLo - iLow(this.strSymbol,this.intPeriod,this.intBar);
      this.C_HasUpShadow  = C_UpShadow > C_ShadowPercent / 100 * C_Body;
      this.C_HasDnShadow  = C_DnShadow > C_ShadowPercent / 100 * C_Body;
      this.C_WhiteBody    = iOpen(this.strSymbol,this.intPeriod,this.intBar) < iClose(this.strSymbol,this.intPeriod,this.intBar);
      this.C_BlackBody    = iOpen(this.strSymbol,this.intPeriod,this.intBar) > iClose(this.strSymbol,this.intPeriod,this.intBar);
      this.C_Range        = iHigh(this.strSymbol,this.intPeriod,this.intBar) - iLow(this.strSymbol,this.intPeriod,this.intBar);
      this.C_RangeAvg     = this.ema_range(this.C_Len);
      this.C_BigRange     = this.C_Range > this.C_RangeAvg;
      this.C_SmallRange   = this.C_Range < this.C_RangeAvg;
      this.C_IsInsideBar  = MathMax(iClose(this.strSymbol,this.intPeriod,this.intBar+1),iOpen(this.strSymbol,this.intPeriod,this.intBar+1)) > C_BodyHi && MathMin(iClose(this.strSymbol,this.intPeriod,this.intBar+1),iOpen(this.strSymbol,this.intPeriod,this.intBar+1)) < C_BodyLo;
      this.C_BodyMiddle   = this.C_Body / 2 + this.C_BodyLo;
      this.C_ShadowEquals = this.blCheckShadowEqual();
      this.C_IsDojiBody   = C_Range > 0 && C_Body <= C_Range * C_DojiBodyPercent / 100;
      this.C_Doji         = C_IsDojiBody && C_ShadowEquals;
      
}

bool clsCandlePattern::blCheckShadowEqual()
{
      if(this.C_UpShadow == this.C_DnShadow)
      {
          return(true);
      }
      else
      {
          if (this.C_UpShadow != 0 && this.C_DnShadow != 0)
          {
             if( (MathAbs(this.C_UpShadow - this.C_DnShadow) / this.C_DnShadow * 100) < this.C_ShadowEqualsPercent && 
                 (MathAbs(this.C_DnShadow - this.C_UpShadow) / this.C_UpShadow * 100) < this.C_ShadowEqualsPercent
               )
              {
                 return(true);
              }
          }
          
      }
      return(false);
}

bool clsCandlePattern::C_PinBarBullish(void)
{
     double high = iHigh(this.strSymbol,this.intPeriod,this.intBar);
     double low  = iLow(this.strSymbol,this.intPeriod,this.intBar);
     double hl2  = (high+low)/2;
     
     if(this.C_SmallBody && this.C_Body > 0 &&
        this.C_BodyLo > hl2 && this.C_HasDnShadow &&
        this.C_DnShadow > 2 * this.C_UpShadow //&&
        //this.C_Range > 0.7 * this.C_RangeAvg
       )
      {
          return(true);
      }
      return(false);
}

bool clsCandlePattern::C_PinBarBearish(void)
{
     double high = iHigh(this.strSymbol,this.intPeriod,this.intBar);
     double low  = iLow(this.strSymbol,this.intPeriod,this.intBar);
     double hl2  = (high+low)/2;
     
     if(this.C_SmallBody && this.C_Body > 0 &&
        this.C_BodyHi < hl2 && this.C_HasUpShadow &&
        this.C_UpShadow  > 2 * this.C_DnShadow //&&
        //this.C_Range > 0.7 * this.C_RangeAvg
        
       )
      {
          return(true);
      }
      return(false);
}

bool clsCandlePattern::C_HammerBullish(void)
{
     double high = iHigh(this.strSymbol,this.intPeriod,this.intBar);
     double low  = iLow(this.strSymbol,this.intPeriod,this.intBar);
     double hl2  = (high+low)/2;
     if (this.C_SmallBody && this.C_Body > 0 && this.C_BodyLo > hl2 && this.C_DnShadow >= this.C_Factor * this.C_Body && this.C_HasUpShadow == false)
     {
         return(true);
     }
     return(false);
}

bool clsCandlePattern::C_ShootingBearish()
{
    double high = iHigh(this.strSymbol,this.intPeriod,this.intBar);
    double low  = iLow(this.strSymbol,this.intPeriod,this.intBar);
    double hl2  = (high+low)/2;
    if (this.C_SmallBody && this.C_Body > 0 && this.C_BodyHi < hl2 && this.C_UpShadow >= this.C_Factor * this.C_Body && this.C_HasDnShadow == false)
    {
        return(true);
    }
    return(false);
}


bool clsCandlePattern::C_BullishEngulfing(void)
{
    //C_WhiteBody and C_LongBody and  and close >= open[1] and open <= close[1] and ( close > open[1] or open < close[1] )
    double close      = iClose(this.strSymbol,this.intPeriod,this.intBar);
    double open       = iOpen(this.strSymbol,this.intPeriod,this.intBar);
    double close_prev = iClose(this.strSymbol,this.intPeriod,this.intBar+1);
    double open_prev  = iOpen(this.strSymbol,this.intPeriod,this.intBar+1);
    if(this.C_WhiteBody && this.C_LongBody && close >= open_prev && open <= close_prev && (close > open_prev || open < close_prev))
    {
        return(true);
    }
    return(false);
}

bool clsCandlePattern::C_BearishEngulfing(void)
{
    //C_BlackBody and C_LongBody  and close <= open[1] and open >= close[1] and ( close < open[1] or open > close[1] )
    double close      = iClose(this.strSymbol,this.intPeriod,this.intBar);
    double open       = iOpen(this.strSymbol,this.intPeriod,this.intBar);
    double close_prev = iClose(this.strSymbol,this.intPeriod,this.intBar+1);
    double open_prev  = iOpen(this.strSymbol,this.intPeriod,this.intBar+1);
    if(this.C_BlackBody && this.C_LongBody && close <= open_prev && open >= close_prev && (close < open_prev || open > close_prev))
    {
        return(true);
    }
    return(false);
}

int clsCandlePattern::Pattern_BreakExtremeEngulf(void)
{
   int D1_candle = iBarShift(this.strSymbol,PERIOD_D1,iTime(this.strSymbol,this.intPeriod,this.intBar));
   double day_low  = iLow(this.strSymbol,PERIOD_D1,D1_candle+1);
   double day_high = iHigh(this.strSymbol,PERIOD_D1,D1_candle+1);
   
   if(this.C_BullishEngulfing())
   {
       for(int i = this.intBar+1; i < this.intBar+4; i++)
       {
            if(iLow(this.strSymbol,this.intPeriod,i) < day_low)
            {
                 return(1);
            }
       }
   }
   if(this.C_BearishEngulfing())
   {
       for(int i = this.intBar+1; i < this.intBar+4; i++)
       {
            if(iHigh(this.strSymbol,this.intPeriod,i) > day_high)
            {
                 return(-1);
            }
       }
   }
   return(0);
}