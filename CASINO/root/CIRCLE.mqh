//+------------------------------------------------------------------+
//|                                                 CircleSimple.mqh |
//|                                Copyright 2017, Alexander Fedosov |
//|                           https://www.mql5.com/en/users/alex2356 |
//+------------------------------------------------------------------+
#include "CANVAS_BASE.mqh"
//+------------------------------------------------------------------+
//| Circular indicator with numerical value and description          |
//+------------------------------------------------------------------+
class CCircleSimple : public CCanvasBase
  {
private:
   //--- Background color 
   color             m_bg_color;
   //--- Frame color
   color             m_border_color;
   //--- Value text color
   color             m_font_color;
   //--- Label text color
   color             m_label_color;
   //--- Transparency
   uchar             m_transparency;
   //--- Frame width
   int               m_border;
   //--- Indicator size
   int               m_radius;
   //--- Value font size
   int               m_font_size;
   //--- Label font size
   int               m_label_font_size;
   //---
   int               m_digits;
   //--- Label
   string            m_label;
public:
                     CCircleSimple(void);
                    ~CCircleSimple(void);
   //--- Set and get background color
   color             Color(void)                      { return(m_bg_color);            }
   void              Color(const color clr)           { m_bg_color=clr;                }
   //--- Set and get size
   int               Radius(void)                     { return(m_radius);              }
   void              Radius(const int r)              { m_radius=r;                    }
   //--- Set and get value font size
   int               FontSize(void)                   { return(m_font_size);           }
   void              FontSize(const int fontsize)     { m_font_size=fontsize;          }
   //--- Set and get label font size
   int               LabelSize(void)                  { return(m_label_font_size);    }
   void              LabelSize(const int fontsize)    { m_label_font_size=fontsize;   }
   //--- Set and get value font color
   color             FontColor(void)                  { return(m_font_color);          }
   void              FontColor(const color fontcolor) { m_font_color=fontcolor;        }
   //--- Set and get label font color
   color             LabelColor(void)                 { return(m_label_color);         }
   void              LabelColor(const color fontcolor){ m_label_color=fontcolor;       }
   //--- Set frame color and width
   void              BorderColor(const color clr)     { m_border_color=clr;            }
   void              BorderSize(const int border)     { m_border=border;               }
   //--- Set and get transparency
   uchar             Alpha(void)                      { return(m_transparency);        }
   void              Alpha(const uchar alpha)         { m_transparency=alpha;          }
   //--- Set and get label value
   string            Label(void)                      { return(m_label);               }
   void              Label(const string label)        { m_label=label;                 }
   //--- Create the indicator
   void              Create(string name,int x,int y);
   //--- Remove the indicator
   void              Delete(void);
   //--- Set and update the indicator value
   void              NewValue(int value);
   void              NewValue(double value);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCircleSimple::CCircleSimple(void) : m_bg_color(clrAliceBlue),
                                     m_border_color(clrRoyalBlue),
                                     m_font_color(clrBlack),
                                     m_label_color(clrBlack),
                                     m_transparency(255),
                                     m_border(5),
                                     m_radius(40),
                                     m_font_size(17),
                                     m_label_font_size(20),
                                     m_digits(2),
                                     m_label("label")
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCircleSimple::~CCircleSimple(void)
  {
  }
//+------------------------------------------------------------------+
//| Create the indicator                                             |
//+------------------------------------------------------------------+
void CCircleSimple::Create(string name,int x,int y)
  {
   int r=m_radius;
//--- Correct the indicator location relative to the radius
   x=(x<r)?r:x;
   y=(y<r)?r:y;
   Name(name);
   X(x);
   Y(y);
   XSize(2*r+1);
   YSize(2*r+1);
   if(!CreateCanvas())
      Print("Error. Can not create Canvas.");
   if(m_border>0)
      m_canvas.FillCircle(r,r,r,ColorToARGB(m_border_color,m_transparency));
   m_canvas.FillCircle(r,r,r-m_border,ColorToARGB(m_bg_color,m_transparency));
//---
   m_canvas.FontSizeSet(m_font_size);
   m_canvas.TextOut(r,r,"0",ColorToARGB(m_font_color,m_transparency),TA_CENTER|TA_VCENTER);
//---
   m_canvas.FontSizeSet(m_label_font_size);
   m_canvas.TextOut(r,r+m_label_font_size,m_label,ColorToARGB(m_label_color,m_transparency),TA_CENTER|TA_VCENTER);
   m_canvas.Update();
  }
//+------------------------------------------------------------------+
//| Set and update the indicator value                               |
//+------------------------------------------------------------------+
void CCircleSimple::NewValue(int value)
  {
   int r=m_radius;
   m_canvas.FillCircle(r,r,r-m_border,ColorToARGB(m_bg_color,m_transparency));
//---
   m_canvas.FontSizeSet(m_font_size);
   m_canvas.TextOut(r,r,IntegerToString(value),ColorToARGB(m_font_color,m_transparency),TA_CENTER|TA_VCENTER);
//---
   m_canvas.FontSizeSet(m_label_font_size);
   m_canvas.TextOut(r,r+m_label_font_size,m_label,ColorToARGB(m_label_color,m_transparency),TA_CENTER|TA_VCENTER);
   m_canvas.Update();
  }
//+------------------------------------------------------------------+
//| Set and update the indicator value                               |
//+------------------------------------------------------------------+
void CCircleSimple::NewValue(double value)
  {
   int r=m_radius;
   m_canvas.FillCircle(r,r,r-m_border,ColorToARGB(m_bg_color,m_transparency));
//---
   m_canvas.FontSizeSet(m_font_size);
   m_canvas.TextOut(r,r,DoubleToString(value,m_digits),ColorToARGB(m_font_color,m_transparency),TA_CENTER|TA_VCENTER);
//---
   m_canvas.FontSizeSet(m_label_font_size);
   m_canvas.TextOut(r,r+m_label_font_size,m_label,ColorToARGB(m_label_color,m_transparency),TA_CENTER|TA_VCENTER);
   m_canvas.Update();
  }
//+------------------------------------------------------------------+
//| Delete the indicator                                             |
//+------------------------------------------------------------------+
void CCircleSimple::Delete(void)
  {
   DeleteCanvas();
  }
//+------------------------------------------------------------------+
