//+------------------------------------------------------------------+
//|                                                    TEST_INDI.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "root/MASTER_CONFIG.mqh"
#include "root/LINEAR_REGRESSION.mqh"
extern int TEST_BAR = 0;
//#property indicator_chart_window
#property indicator_separate_window
#property indicator_buffers 8
double Buffer_1[];
double Buffer_2[];
double Buffer_3[];
double Buffer_4[];
double Buffer_5[];
double Buffer_6[];
double Buffer_7[];
double Buffer_8[];

clsLinearRegression *LR;

datetime expiryDate = D'2022.08.15 00:00'; 
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
     if(TimeCurrent() > expiryDate)
    {
        return(INIT_FAILED);
    }
//--- indicator buffers mapping
    LR = new clsLinearRegression(ChartSymbol(),ChartPeriod());
    int t1;
    t1=0 ;  SetIndexBuffer(t1,Buffer_1); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrRed); SetIndexLabel(t1,"BUFFER 1");
    t1+=1 ; SetIndexBuffer(t1,Buffer_2); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrBlue);  SetIndexLabel(t1,"BUFFER 2");
    t1+=1 ; SetIndexBuffer(t1,Buffer_3); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrGreenYellow); SetIndexLabel(t1,"BUFFER 3");
    t1+=1 ; SetIndexBuffer(t1,Buffer_4); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrBlue);  SetIndexLabel(t1,"BUFFER 4");
    t1+=1 ; SetIndexBuffer(t1,Buffer_5); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_HISTOGRAM,STYLE_SOLID, 3, clrBlue); SetIndexLabel(t1,"BUFFER 5");
    t1+=1 ; SetIndexBuffer(t1,Buffer_6); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_LINE,STYLE_SOLID, 1, clrGreen);  SetIndexLabel(t1,"BUFFER 6");
    t1+=1 ; SetIndexBuffer(t1,Buffer_7); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 1, clrRed);  SetIndexLabel(t1,"BUFFER 7");
    t1+=1 ; SetIndexBuffer(t1,Buffer_8); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 1, clrRed);  SetIndexLabel(t1,"BUFFER 8");
//---
   return(INIT_SUCCEEDED);
  }
  
int deinit()
  {
//----
   if(CheckPointer(LR) == POINTER_DYNAMIC) delete LR; 
   return(0);
  }

double dblParkinsonVolatility(int bar)
{
    double sum_hr_squared = 0;
    for(int i = bar; i <= 24; i++)
    {
         double high = MathLog10(iHigh(ChartSymbol(),ChartPeriod(),i));
         double low  = MathLog10(iLow(ChartSymbol(),ChartPeriod(),i));
         double hr_squared = MathPow((high-low),2);
         sum_hr_squared += hr_squared;
    }
    double value = MathSqrt((sum_hr_squared / (4 * MathLog10(2))));
    
    return(value/pips(ChartSymbol()));
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int uncalculated_bar = rates_total - prev_calculated;
   //for(int i = 0; i <= uncalculated_bar - 1; i++)
   //for(int i = 23; i >= 0; i--)
   for(int i = uncalculated_bar - 1 - 400; i >= 0; i--)
   {
       LR.Updater(time[i]);
       if(ArraySize(LR.dblCloses) > 0)
       {
          if(ArraySize(LR.dblClose_ms) > 7)
          {
             //Buffer_1[i] = LR.intOpenTrend;// dblParkinsonVolatility(i);
             //Buffer_2[i] = LR.intHighTrend;
             //Buffer_3[i] = LR.intLowTrend;
             //Buffer_4[i] = LR.intCloseTrend;
             if(
                  MathAbs(LR.dblClose_ms[0]) > MathAbs(LR.dblClose_ms[1]) &&
                  MathAbs(LR.dblClose_ms[1]) > MathAbs(LR.dblClose_ms[2]) &&
                  MathAbs(LR.dblClose_ms[2]) > MathAbs(LR.dblClose_ms[3]) &&
                  MathAbs(LR.dblClose_ms[3]) > MathAbs(LR.dblClose_ms[4]) &&
                  MathAbs(LR.dblClose_ms[4]) > MathAbs(LR.dblClose_ms[5]) &&
                  MathAbs(LR.dblClose_ms[5]) > MathAbs(LR.dblClose_ms[6]) &&
                  MathAbs(LR.dblClose_ms[6]) > MathAbs(LR.dblClose_ms[7]) 
               )
             {
                  Buffer_5[i] = 2;//MathAbs(LR.dblClose_ms[0]/pips(ChartSymbol())) < 0.2 ? 2 : 0 ;
             }
             Buffer_6[i] = LR.dblClose_ms[0]/pips(ChartSymbol());
          }
       }
       //TEST PLOT LINE
       if(i == 0)
       {
           for(int i = 0; i < ArraySize(LR.dblClose_LR); i++)
           {
              //Buffer_6[i] = LR.dblClose_LR[i];
           }
       }
       
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
