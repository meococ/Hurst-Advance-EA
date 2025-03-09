//+------------------------------------------------------------------+
//|                          SignalGeneration.mqh                     |
//|                  Copyright 2025, Trading Systems Development       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Systems Development"
#property link      "https://www.mql5.com"

#include <Math/Stat/Math.mqh>
#include "../Utils/Common.mqh"
#include "../Core/MarketStructure.mqh"

//+------------------------------------------------------------------+
//| Ma trận xác nhận đa chiều                                         |
//+------------------------------------------------------------------+
class CConfirmationMatrix
  {
private:
   SignalMatrix      m_signalMatrix;                   // Ma trận điểm tính hiệu
   double            m_hurstExponent;                  // Giá trị Hurst hiện tại
   ENUM_MARKET_MODE  m_marketMode;                     // Chế độ thị trường hiện tại
   
   // Các ngưỡng đánh giá tín hiệu
   double            m_strongSignalThreshold;          // Ngưỡng tín hiệu mạnh (mặc định 8.0)
   double            m_moderateSignalThreshold;        // Ngưỡng tín hiệu trung bình (mặc định 6.0)
   double            m_weakSignalThreshold;            // Ngưỡng tín hiệu yếu (mặc định 4.0)
   
   // Điều chỉnh trọng số theo chế độ thị trường
   void              AdjustWeightsByMarketMode();
   // Áp dụng các quy tắc bổ sung
   void              ApplyAdditionalRules();

public:
                     CConfirmationMatrix();
                    ~CConfirmationMatrix();
   
   // Khởi tạo ma trận với các giá trị mặc định
   void              Initialize();
   
   // Cập nhật chế độ thị trường 
   void              UpdateMarketMode(ENUM_MARKET_MODE mode, double hurstExponent);
   
   // Đặt điểm cho mỗi phân tích riêng biệt 
   void              SetHurstScore(double score, string desc = "");
   void              SetPatternScore(double score, string desc = "");
   void              SetTrendlineScore(double score, string desc = "");
   void              SetSMCScore(double score, string desc = "");
   void              SetICPScore(double score, string desc = "");
   void              SetWyckoffScore(double score, string desc = "");
   void              SetRSIScore(double score, string desc = "");
   
   // Tính toán tổng điểm cuối cùng
   double            CalculateTotalScore();
   
   // Đánh giá chất lượng tín hiệu
   ENUM_SIGNAL_QUALITY GetSignalQuality();
   
   // Cập nhật mô tả tín hiệu với các chi tiết quan trọng
   void              UpdateSignalDescription();
   
   // Lấy mô tả đầy đủ
   string            GetSignalDescription() { return m_signalMatrix.description; }
   
   // Lấy ma trận tín hiệu
   SignalMatrix     *GetSignalMatrix() { return &m_signalMatrix; }
  };

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CConfirmationMatrix::CConfirmationMatrix()
  {
   Initialize();
  }

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CConfirmationMatrix::~CConfirmationMatrix()
  {
   // Không có bộ nhớ cấp phát động để giải phóng
  }

//+------------------------------------------------------------------+
//| Khởi tạo ma trận với các giá trị mặc định                         |
//+------------------------------------------------------------------+
void CConfirmationMatrix::Initialize()
  {
   m_signalMatrix.Init();
   
   m_hurstExponent = 0.5;
   m_marketMode = MARKET_MODE_UNKNOWN;
   
   m_strongSignalThreshold = 8.0;
   m_moderateSignalThreshold = 6.0;
   m_weakSignalThreshold = 4.0;
  }

//+------------------------------------------------------------------+
//| Cập nhật chế độ thị trường                                        |
//+------------------------------------------------------------------+
void CConfirmationMatrix::UpdateMarketMode(ENUM_MARKET_MODE mode, double hurstExponent)
  {
   m_marketMode = mode;
   m_hurstExponent = hurstExponent;
   
   // Điều chỉnh trọng số dựa trên chế độ thị trường
   AdjustWeightsByMarketMode();
  }

//+------------------------------------------------------------------+
//| Điều chỉnh trọng số theo chế độ thị trường                        |
//+------------------------------------------------------------------+
void CConfirmationMatrix::AdjustWeightsByMarketMode()
{
   // Khởi tạo các trọng số mặc định
   m_signalMatrix.hurstWeight = 1.0;    // Trọng số Hurst
   m_signalMatrix.patternWeight = 1.0;  // Trọng số mẫu hình giá
   m_signalMatrix.trendlineWeight = 1.0; // Trọng số trendline
   m_signalMatrix.icpWeight = 1.0;      // Trọng số ICP
   m_signalMatrix.smcWeight = 1.0;      // Trọng số SMC
   m_signalMatrix.wyckoffWeight = 1.0;  // Trọng số Wyckoff
   m_signalMatrix.rsiWeight = 1.0;      // Trọng số RSI
   
   // Điều chỉnh trọng số dựa trên chế độ thị trường
   switch(m_marketMode) {
      // Thị trường xu hướng - tin cậy Hurst, trendline, ICP
      case MARKET_MODE_TRENDING:
         m_signalMatrix.hurstWeight = 1.5;     // Tăng trọng số Hurst
         m_signalMatrix.trendlineWeight = 1.3; // Tăng trọng số trendline
         m_signalMatrix.icpWeight = 1.2;       // Tăng trọng số ICP
         m_signalMatrix.rsiWeight = 0.7;       // Giảm trọng số RSI
         
         // Điều chỉnh thêm dựa trên giá trị Hurst
         if(m_hurstExponent > 0.6) {
            m_signalMatrix.hurstWeight = 1.8;     // Tăng trọng số Hurst cao hơn
            m_signalMatrix.patternWeight = 1.2;   // Tăng trọng số mẫu hình
            m_signalMatrix.rsiWeight = 0.5;       // Giảm trọng số RSI nhiều hơn
         }
         break;
         
      // Thị trường đi ngang - tin cậy pattern, Wyckoff, SMC
      case MARKET_MODE_RANGING:
         m_signalMatrix.patternWeight = 1.3;   // Tăng trọng số mẫu hình
         m_signalMatrix.wyckoffWeight = 1.4;   // Tăng trọng số Wyckoff
         m_signalMatrix.smcWeight = 1.3;       // Tăng trọng số SMC
         m_signalMatrix.hurstWeight = 0.8;     // Giảm trọng số Hurst
         
         // Điều chỉnh thêm dựa trên giá trị Hurst
         if(m_hurstExponent > 0.45 && m_hurstExponent < 0.55) {
            m_signalMatrix.rsiWeight = 1.3;       // Tăng trọng số RSI
            m_signalMatrix.hurstWeight = 0.7;     // Giảm trọng số Hurst thêm
         }
         break;
         
      // Thị trường đảo chiều - tin cậy RSI, pattern
      case MARKET_MODE_REVERSAL:
         m_signalMatrix.rsiWeight = 1.5;       // Tăng trọng số RSI
         m_signalMatrix.patternWeight = 1.4;   // Tăng trọng số mẫu hình
         m_signalMatrix.hurstWeight = 1.2;     // Tăng nhẹ trọng số Hurst
         m_signalMatrix.trendlineWeight = 0.9; // Giảm trọng số trendline
         
         // Điều chỉnh thêm dựa trên giá trị Hurst
         if(m_hurstExponent < 0.42) {
            m_signalMatrix.hurstWeight = 1.4;     // Tăng trọng số Hurst
            m_signalMatrix.rsiWeight = 1.7;       // Tăng trọng số RSI cao hơn
         }
         break;
         
      // Thị trường biến động - cẩn trọng, giảm tất cả trừ SMC
      case MARKET_MODE_VOLATILE:
         m_signalMatrix.smcWeight = 1.5;       // Tăng trọng số SMC
         m_signalMatrix.patternWeight = 0.8;   // Giảm trọng số mẫu hình
         m_signalMatrix.hurstWeight = 0.8;     // Giảm trọng số Hurst
         m_signalMatrix.trendlineWeight = 0.7; // Giảm trọng số trendline
         m_signalMatrix.icpWeight = 0.9;       // Giảm trọng số ICP
         m_signalMatrix.wyckoffWeight = 1.1;   // Tăng nhẹ trọng số Wyckoff
         break;
         
      // Chế độ mặc định - cân bằng
      default:
         // Giữ trọng số mặc định
         break;
   }
   
   // Điều chỉnh dựa trên phản hồi từ thị trường
   ApplyAdditionalRules();
}

//+------------------------------------------------------------------+
//| Thiết lập điểm số Hurst                                           |
//+------------------------------------------------------------------+
void CConfirmationMatrix::SetHurstScore(double score, string desc = "")
  {
   m_signalMatrix.hurstScore = score;
   
   if(desc != "")
      m_signalMatrix.description += "Hurst: " + desc + ". ";
  }

//+------------------------------------------------------------------+
//| Thiết lập điểm số mô hình giá                                     |
//+------------------------------------------------------------------+
void CConfirmationMatrix::SetPatternScore(double score, string desc = "")
  {
   m_signalMatrix.patternScore = score;
   
   if(desc != "")
      m_signalMatrix.description += "Pattern: " + desc + ". ";
  }

//+------------------------------------------------------------------+
//| Thiết lập điểm số trendline                                       |
//+------------------------------------------------------------------+
void CConfirmationMatrix::SetTrendlineScore(double score, string desc = "")
  {
   m_signalMatrix.trendlineScore = score;
   
   if(desc != "")
      m_signalMatrix.description += "Trendline: " + desc + ". ";
  }

//+------------------------------------------------------------------+
//| Thiết lập điểm số SMC                                             |
//+------------------------------------------------------------------+
void CConfirmationMatrix::SetSMCScore(double score, string desc = "")
  {
   m_signalMatrix.smcScore = score;
   
   if(desc != "")
      m_signalMatrix.description += "SMC: " + desc + ". ";
  }

//+------------------------------------------------------------------+
//| Thiết lập điểm số ICP                                             |
//+------------------------------------------------------------------+
void CConfirmationMatrix::SetICPScore(double score, string desc = "")
  {
   m_signalMatrix.icpScore = score;
   
   if(desc != "")
      m_signalMatrix.description += "ICP: " + desc + ". ";
  }

//+------------------------------------------------------------------+
//| Thiết lập điểm số Wyckoff                                         |
//+------------------------------------------------------------------+
void CConfirmationMatrix::SetWyckoffScore(double score, string desc = "")
  {
   m_signalMatrix.wyckoffScore = score;
   
   if(desc != "")
      m_signalMatrix.description += "Wyckoff: " + desc + ". ";
  }

//+------------------------------------------------------------------+
//| Thiết lập điểm số RSI                                             |
//+------------------------------------------------------------------+
void CConfirmationMatrix::SetRSIScore(double score, string desc = "")
  {
   m_signalMatrix.rsiScore = score;
   
   if(desc != "")
      m_signalMatrix.description += "RSI: " + desc + ". ";
  }

//+------------------------------------------------------------------+
//| Tính toán tổng điểm cuối cùng                                     |
//+------------------------------------------------------------------+
double CConfirmationMatrix::CalculateTotalScore()
{
   // Tính tổng điểm theo trọng số
   double weightedScore = 
      m_signalMatrix.hurstScore * m_signalMatrix.hurstWeight +
      m_signalMatrix.patternScore * m_signalMatrix.patternWeight +
      m_signalMatrix.trendlineScore * m_signalMatrix.trendlineWeight +
      m_signalMatrix.smcScore * m_signalMatrix.smcWeight +
      m_signalMatrix.icpScore * m_signalMatrix.icpWeight +
      m_signalMatrix.wyckoffScore * m_signalMatrix.wyckoffWeight +
      m_signalMatrix.rsiScore * m_signalMatrix.rsiWeight;
      
   // Tính tổng trọng số
   double totalWeight = 
      m_signalMatrix.hurstWeight +
      m_signalMatrix.patternWeight +
      m_signalMatrix.trendlineWeight +
      m_signalMatrix.smcWeight +
      m_signalMatrix.icpWeight +
      m_signalMatrix.wyckoffWeight +
      m_signalMatrix.rsiWeight;
      
   // Chuẩn hóa điểm trong khoảng -1 đến 1
   double normalizedScore = weightedScore / totalWeight;
   
   // Áp dụng sự ảnh hưởng của Hurst Exponent
   // Khi Hurst > 0.6, tăng độ tin cậy của tín hiệu theo xu hướng
   // Khi Hurst < 0.4, tăng độ tin cậy của tín hiệu đảo chiều
   double hurstMultiplier = 1.0;
   
   // Điều chỉnh bội số Hurst dựa trên giá trị Hurst và hướng tín hiệu
   if(m_hurstExponent > 0.6) { // Thị trường có xu hướng mạnh
      // Trong thị trường xu hướng, tăng cường tín hiệu cùng chiều
      // Giảm tín hiệu ngược chiều
      if((normalizedScore > 0 && m_signalMatrix.hurstScore > 0) || 
         (normalizedScore < 0 && m_signalMatrix.hurstScore < 0)) {
         // Tín hiệu cùng chiều với Hurst
         hurstMultiplier = 1.0 + (m_hurstExponent - 0.6) * 2.0;
      } else {
         // Tín hiệu ngược chiều với Hurst
         hurstMultiplier = 1.0 - (m_hurstExponent - 0.6) * 1.5;
      }
   } 
   else if(m_hurstExponent < 0.4) { // Thị trường đảo chiều mạnh
      // Trong thị trường đảo chiều, tăng cường tín hiệu ngược xu hướng
      if((normalizedScore > 0 && m_marketMode == MARKET_MODE_TRENDING && m_signalMatrix.hurstScore < 0) || 
         (normalizedScore < 0 && m_marketMode == MARKET_MODE_TRENDING && m_signalMatrix.hurstScore > 0)) {
         // Tín hiệu đảo chiều phù hợp với Hurst
         hurstMultiplier = 1.0 + (0.4 - m_hurstExponent) * 2.0;
      }
   }
   
   // Áp dụng bội số và lưu lại kết quả
   m_signalMatrix.totalScore = normalizedScore * hurstMultiplier;
   
   return m_signalMatrix.totalScore;
}

//+------------------------------------------------------------------+
//| Áp dụng các quy tắc bổ sung dựa trên sự kết hợp của các tín hiệu  |
//+------------------------------------------------------------------+
void CConfirmationMatrix::ApplyAdditionalRules()
  {
   // Quy tắc 1: Nếu Hurst và Trendline đều cho tín hiệu mạnh trong xu hướng
   if(m_marketMode == MARKET_MODE_TRENDING && 
      m_signalMatrix.hurstScore >= 8.0 && 
      m_signalMatrix.trendlineScore >= 8.0)
     {
      // Tăng điểm SMC
      m_signalMatrix.smcScore = MathMax(m_signalMatrix.smcScore * 1.2, 10.0);
     }
   
   // Quy tắc 2: Nếu RSI và Wyckoff đều cho tín hiệu mạnh trong đảo chiều
   if(m_marketMode == MARKET_MODE_REVERSAL && 
      m_signalMatrix.rsiScore >= 8.0 && 
      m_signalMatrix.wyckoffScore >= 8.0)
     {
      // Tăng điểm mô hình giá
      m_signalMatrix.patternScore = MathMax(m_signalMatrix.patternScore * 1.2, 10.0);
     }
   
   // Quy tắc 3: Nếu mô hình giá và SMC đều cho tín hiệu kém trong bất kỳ môi trường nào
   if(m_signalMatrix.patternScore <= 3.0 && m_signalMatrix.smcScore <= 3.0)
     {
      // Giảm điểm ICP
      m_signalMatrix.icpScore = MathMin(m_signalMatrix.icpScore * 0.8, m_signalMatrix.icpScore);
     }
   
   // Quy tắc 4: Khi có sự bất đồng ý kiến giữa Hurst và các phân tích khác
   double otherAvgScore = (m_signalMatrix.patternScore + 
                           m_signalMatrix.trendlineScore + 
                           m_signalMatrix.smcScore + 
                           m_signalMatrix.icpScore + 
                           m_signalMatrix.wyckoffScore + 
                           m_signalMatrix.rsiScore) / 6.0;
                           
   if(MathAbs(m_signalMatrix.hurstScore - otherAvgScore) > 3.0)
     {
      // Giảm điểm Hurst nếu nó mâu thuẫn với phân tích khác
      double adjustment = 0.9;
      m_signalMatrix.hurstScore *= adjustment;
     }
  }

//+------------------------------------------------------------------+
//| Đánh giá chất lượng tín hiệu dựa trên điểm số                     |
//+------------------------------------------------------------------+
ENUM_SIGNAL_QUALITY CConfirmationMatrix::GetSignalQuality()
  {
   double totalScore = CalculateTotalScore();
   
   if(totalScore >= m_strongSignalThreshold)
      return SIGNAL_STRONG;
   else if(totalScore >= m_moderateSignalThreshold)
      return SIGNAL_MODERATE;
   else if(totalScore >= m_weakSignalThreshold)
      return SIGNAL_WEAK;
   else
      return SIGNAL_INVALID;
  }

//+------------------------------------------------------------------+
//| Cập nhật mô tả tín hiệu với thông tin tổng hợp                    |
//+------------------------------------------------------------------+
void CConfirmationMatrix::UpdateSignalDescription()
  {
   ENUM_SIGNAL_QUALITY quality = GetSignalQuality();
   double score = m_signalMatrix.totalScore;
   
   string qualityText = "";
   switch(quality)
     {
      case SIGNAL_STRONG:
         qualityText = "Mạnh";
         break;
      case SIGNAL_MODERATE:
         qualityText = "Trung bình";
         break;
      case SIGNAL_WEAK:
         qualityText = "Yếu";
         break;
      default:
         qualityText = "Không hợp lệ";
         break;
     }
   
   // Thêm thông tin tổng hợp vào mô tả
   m_signalMatrix.description = StringFormat("Tín hiệu %s (%.2f/10): %s", 
                                            qualityText, 
                                            score, 
                                            m_signalMatrix.description);
  }

//+------------------------------------------------------------------+
//| Class for Signal Generation                                       |
//+------------------------------------------------------------------+
class CSignalGenerator {
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   ENUM_SCALPING_MODE m_scalpingMode;
   
   // Market structure reference
   CMarketStructure *m_marketStructure;
   
   // Ma trận xác nhận đa chiều
   CConfirmationMatrix *m_confirmationMatrix;
   
   // Signal generation parameters
   bool m_useMACDDivergence;
   bool m_useEMACrossover;
   int m_macdFast;
   int m_macdSlow;
   int m_macdSignalPeriod;
   int m_stochK;
   int m_stochD;
   int m_stochSlowing;
   double m_stochUpperLevel;
   double m_stochLowerLevel;
   int m_emaScalpPeriod;
   int m_emaFastPeriod;
   int m_emaMediumPeriod;
   int m_emaLongPeriod;
   
   // Signal tracking
   int m_lastSignalDirection;
   datetime m_lastSignalTime;
   int m_signalChangeMinutes;
   
   // Thông tin tín hiệu gần nhất
   SignalInfo m_lastSignal;
   
   // Signal detection methods
   bool IsTrendFollowingBuySignal();
   bool IsTrendFollowingSellSignal();
   bool IsReversalBuySignal();
   bool IsReversalSellSignal();
   bool IsRangeBuySignal();
   bool IsRangeSellSignal();
   
   // Divergence detection
   bool IsBullishDivergence(int lookbackBars);
   bool IsBearishDivergence(int lookbackBars);
   
   // Pattern detection
   bool IsBullishEngulfing();
   bool IsBearishEngulfing();
   bool IsMorningStar();
   bool IsEveningStar();
   
   // Candlestick analysis
   bool IsDoji(int barIndex);
   bool IsBullishCandle(int barIndex);
   bool IsBearishCandle(int barIndex);
   
   // Technical indicator helpers
   bool IsEMACrossUp();
   bool IsEMACrossDown();
   bool IsStochasticCrossUp();
   bool IsStochasticCrossDown();
   
   // Check if signal can be generated at current time
   bool CanGenerateSignal(int direction);
   
   // Các phương thức đánh giá tín hiệu cho ma trận xác nhận
   void EvaluateHurstAnalysis();
   void EvaluatePricePatterns(ENUM_TRIANGLE_TYPE triangleType, bool breakoutDetected);
   void EvaluateTrendlines(bool supportNearby, bool resistanceNearby, bool hasValidChannel);
   void EvaluateRSI(double rsi, double rsiPrev, bool bullDivergence, bool bearDivergence, MultiTimeframeRSI mtfRsi, bool rsiValid);
   void EvaluateSMC();
   void EvaluateICP();
   void EvaluateWyckoff();
   
   // Xác định tín hiệu mua/bán chiếm ưu thế
   bool IsBuySignalDominant(SignalMatrix *matrix);
   bool IsSellSignalDominant(SignalMatrix *matrix);
   
public:
   // Constructor
   CSignalGenerator(
      string symbol,
      ENUM_TIMEFRAMES timeframe,
      CMarketStructure *marketStructure,
      ENUM_SCALPING_MODE scalpingMode = SCALPING_ALL,
      bool useMACDDivergence = true,
      bool useEMACrossover = true,
      int macdFast = 12,
      int macdSlow = 26,
      int macdSignalPeriod = 9,
      int stochK = 5,
      int stochD = 3,
      int stochSlowing = 3,
      double stochUpperLevel = 80.0,
      double stochLowerLevel = 20.0,
      int emaScalpPeriod = 8,
      int emaFastPeriod = 21,
      int emaMediumPeriod = 50,
      int emaLongPeriod = 200,
      int signalChangeMinutes = 15
   );
   
   // Destructor
   ~CSignalGenerator()
     {
      // Giải phóng ma trận xác nhận
      if(m_confirmationMatrix != NULL)
        {
         delete m_confirmationMatrix;
         m_confirmationMatrix = NULL;
        }
     }
   
   // Update strategy parameters
   void UpdateParameters(
      ENUM_SCALPING_MODE scalpingMode,
      bool useMACDDivergence,
      bool useEMACrossover,
      int emaScalpPeriod,
      int emaFastPeriod,
      int emaMediumPeriod,
      int emaLongPeriod
   );
   
   // Check for trading signals
   SignalInfo CheckForSignals();
   
   // Get string description of last signal
   string GetLastSignalDescription() const;
   
   // Get last signal direction (1=buy, -1=sell, 0=none)
   int GetLastSignalDirection() const { return m_lastSignalDirection; }
   
   // Get time since last signal
   int GetMinutesSinceLastSignal() const;
   
   // Check if there are any potential signals coming
   bool HasPotentialSignals(int direction);
   
   // Set minimum time between signal changes
   void SetSignalChangeMinutes(int minutes) { m_signalChangeMinutes = minutes; }
   
   // Check scalping mode
   bool IsModeAllowed(int signalType);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CSignalGenerator::CSignalGenerator(
   string symbol,
   ENUM_TIMEFRAMES timeframe,
   CMarketStructure *marketStructure,
   ENUM_SCALPING_MODE scalpingMode,
   bool useMACDDivergence,
   bool useEMACrossover,
   int macdFast,
   int macdSlow,
   int macdSignalPeriod,
   int stochK,
   int stochD,
   int stochSlowing,
   double stochUpperLevel,
   double stochLowerLevel,
   int emaScalpPeriod,
   int emaFastPeriod,
   int emaMediumPeriod,
   int emaLongPeriod,
   int signalChangeMinutes
) {
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_marketStructure = marketStructure;
   m_scalpingMode = scalpingMode;
   
   m_useMACDDivergence = useMACDDivergence;
   m_useEMACrossover = useEMACrossover;
   m_macdFast = macdFast;
   m_macdSlow = macdSlow;
   m_macdSignalPeriod = macdSignalPeriod;
   m_stochK = stochK;
   m_stochD = stochD;
   m_stochSlowing = stochSlowing;
   m_stochUpperLevel = stochUpperLevel;
   m_stochLowerLevel = stochLowerLevel;
   m_emaScalpPeriod = emaScalpPeriod;
   m_emaFastPeriod = emaFastPeriod;
   m_emaMediumPeriod = emaMediumPeriod;
   m_emaLongPeriod = emaLongPeriod;
   
   m_signalChangeMinutes = signalChangeMinutes;
   m_lastSignalDirection = 0;
   m_lastSignalTime = 0;
   
   // Khởi tạo ma trận xác nhận
   m_confirmationMatrix = new CConfirmationMatrix();
}

//+------------------------------------------------------------------+
//| Update strategy parameters                                        |
//+------------------------------------------------------------------+
void CSignalGenerator::UpdateParameters(
   ENUM_SCALPING_MODE scalpingMode,
   bool useMACDDivergence,
   bool useEMACrossover,
   int emaScalpPeriod,
   int emaFastPeriod,
   int emaMediumPeriod,
   int emaLongPeriod
) {
   m_scalpingMode = scalpingMode;
   m_useMACDDivergence = useMACDDivergence;
   m_useEMACrossover = useEMACrossover;
   m_emaScalpPeriod = emaScalpPeriod;
   m_emaFastPeriod = emaFastPeriod;
   m_emaMediumPeriod = emaMediumPeriod;
   m_emaLongPeriod = emaLongPeriod;
}

//+------------------------------------------------------------------+
//| Check for trading signals                                         |
//+------------------------------------------------------------------+
SignalInfo CSignalGenerator::CheckForSignals()
{
   if(!CanGenerateSignal(0)) return SignalInfo();
   
   // Đảm bảo Market Structure đã được cập nhật
   if(m_marketStructure == NULL)
      return SignalInfo();
      
   // Lấy thông tin Hurst đa tầng
   double shortTermHurst = m_marketStructure.GetShortTermHurst();
   double mediumTermHurst = m_marketStructure.GetMediumTermHurst();
   double longTermHurst = m_marketStructure.GetLongTermHurst();
   bool hurstAlignedTrend = m_marketStructure.IsHurstAlignedForTrend();
   bool hurstAlignedReversion = m_marketStructure.IsHurstAlignedForReversal();
      
   // Cập nhật chế độ thị trường cho ma trận xác nhận
   ENUM_MARKET_MODE marketMode = m_marketStructure.GetMarketMode();
   double hurstExponent = m_marketStructure.GetHurstExponent();
   m_confirmationMatrix.UpdateMarketMode(marketMode, hurstExponent);
   
   // Lấy thông tin RSI nâng cao
   double rsi = m_marketStructure.GetRSI();
   double rsiPrev = m_marketStructure.GetPreviousRSI();
   double dynamicRsiOverbought = m_marketStructure.GetDynamicRSIOverbought();
   double dynamicRsiOversold = m_marketStructure.GetDynamicRSIOversold();
   bool rsiBullDivergence = m_marketStructure.IsRSIBullishDivergence();
   bool rsiBearDivergence = m_marketStructure.IsRSIBearishDivergence();
   MultiTimeframeRSI mtfRsi = m_marketStructure.GetMultiTimeframeRSI();
   bool rsiValid = true; // Default to true
   
   // Determine if RSI is valid based on Hurst alignment
   if (hurstAlignedTrend && rsi < 30) {
      rsiValid = false; // Oversold RSI may not be valid in strong trend
   }
   else if (hurstAlignedTrend && rsi > 70) {
      rsiValid = false; // Overbought RSI may not be valid in strong trend
   }
   else if (hurstAlignedReversion) {
      rsiValid = true; // RSI signals are more valid in mean-reverting markets
   }
   
   // Lấy thông tin trendline
   bool supportNearby = m_marketStructure.IsSupportTrendlineNearby();
   bool resistanceNearby = m_marketStructure.IsResistanceTrendlineNearby();
   bool breakoutDetected = false;
   bool breakoutIsBullish = false;
   if (m_marketStructure.CheckPatternBreakout(breakoutIsBullish)) {
      breakoutDetected = true;
   }
   ENUM_TRIANGLE_TYPE triangleType = m_marketStructure.GetTriangleType();
   bool hasValidChannel = m_marketStructure.HasValidChannel();
   
   // Khởi tạo ma trận điểm tín hiệu
   m_confirmationMatrix.Initialize();
   
   // Đánh giá tín hiệu từ phân tích Hurst
   EvaluateHurstAnalysis();
   
   // Đánh giá tín hiệu từ mô hình giá
   EvaluatePricePatterns(triangleType, breakoutDetected);
   
   // Đánh giá tín hiệu từ trendline
   EvaluateTrendlines(supportNearby, resistanceNearby, hasValidChannel);
   
   // Đánh giá tín hiệu từ RSI
   EvaluateRSI(rsi, rsiPrev, rsiBullDivergence, rsiBearDivergence, mtfRsi, rsiValid);
   
   // Đánh giá tín hiệu từ SMC
   EvaluateSMC();
   
   // Đánh giá tín hiệu từ ICP
   EvaluateICP();
   
   // Đánh giá tín hiệu từ Wyckoff
   EvaluateWyckoff();
   
   // Tính toán tổng điểm
   double totalScore = m_confirmationMatrix.CalculateTotalScore();
   
   // Cập nhật mô tả tín hiệu
   m_confirmationMatrix.UpdateSignalDescription();
   
   // Xác định loại tín hiệu dựa trên tổng điểm
   ENUM_SIGNAL_QUALITY quality = m_confirmationMatrix.GetSignalQuality();
   
   // Tạo tín hiệu giao dịch nếu đủ mạnh và phù hợp với chế độ thị trường
   if(quality >= SIGNAL_MODERATE)
   {
      SignalMatrix *matrix = m_confirmationMatrix.GetSignalMatrix();
      string signalType = "Unknown";
      
      // Điều chỉnh ngưỡng tín hiệu dựa trên Hurst đa tầng
      double signalThreshold = 0.2; // Mặc định
      
      // Điều chỉnh ngưỡng dựa trên thông tin Hurst
      if (hurstAlignedTrend) {
         // Trong thị trường có xu hướng mạnh, yêu cầu tín hiệu rõ ràng hơn
         signalThreshold = 0.4;
         signalType = "Trend";
      }
      else if (hurstAlignedReversion) {
         // Trong thị trường đảo chiều, có thể chấp nhận tín hiệu yếu hơn
         signalThreshold = 0.15;
         signalType = "Mean Reversion";
      }
      
      // Xác định hướng tín hiệu dựa trên các phân tích
      if(matrix.totalScore > signalThreshold && IsBuySignalDominant(matrix))
      {
         // Tạo tín hiệu mua
         m_lastSignal.type = SIGNAL_BUY;
         m_lastSignal.strength = (int)(matrix.totalScore * 10);
         m_lastSignal.description = signalType + " BUY: " + matrix.description;
         m_lastSignal.entryPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         m_lastSignal.time = TimeCurrent();
         m_lastSignalDirection = 1;
         m_lastSignalTime = TimeCurrent();
         
         return SignalInfo(true, 1, m_lastSignal.strength, m_lastSignal.description, m_lastSignal.entryPrice, 0, 0, m_marketStructure.GetMarketStructure(), m_lastSignal.time);
      }
      else if(matrix.totalScore < -signalThreshold && IsSellSignalDominant(matrix))
      {
         // Tạo tín hiệu bán
         m_lastSignal.type = SIGNAL_SELL;
         m_lastSignal.strength = (int)(MathAbs(matrix.totalScore) * 10);
         m_lastSignal.description = signalType + " SELL: " + matrix.description;
         m_lastSignal.entryPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         m_lastSignal.time = TimeCurrent();
         m_lastSignalDirection = -1;
         m_lastSignalTime = TimeCurrent();
         
         return SignalInfo(true, -1, m_lastSignal.strength, m_lastSignal.description, m_lastSignal.entryPrice, 0, 0, m_marketStructure.GetMarketStructure(), m_lastSignal.time);
      }
   }
   
   return SignalInfo();
}

//+------------------------------------------------------------------+
//| Check if signal can be generated at current time                  |
//+------------------------------------------------------------------+
bool CSignalGenerator::CanGenerateSignal(int direction) {
   // Check if enough time has passed since last signal
   if(m_lastSignalTime > 0) {
      int minutesPassed = GetMinutesSinceLastSignal();
      if(minutesPassed < m_signalChangeMinutes) {
         return false;
      }
      
      // If same direction as last signal, always allow
      if(direction == m_lastSignalDirection) {
         return true;
      }
      
      // If opposite direction, require 2x the minutes
      if(direction == -m_lastSignalDirection && minutesPassed < (m_signalChangeMinutes * 2)) {
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get minutes since last signal                                     |
//+------------------------------------------------------------------+
int CSignalGenerator::GetMinutesSinceLastSignal() const {
   if(m_lastSignalTime == 0)
      return 9999;
      
   datetime currentTime = TimeCurrent();
   return (int)((currentTime - m_lastSignalTime) / 60);
}

//+------------------------------------------------------------------+
//| Check if strategy mode is allowed                                 |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsModeAllowed(int signalType) {
   // signalType: 1=trend, 2=reversal, 3=range
   
   // If all strategies are enabled
   if(m_scalpingMode == SCALPING_ALL)
      return true;
      
   // Check specific strategy types
   switch(signalType) {
      case 1: // Trend
         return (m_scalpingMode == SCALPING_TREND_ONLY);
         
      case 2: // Reversal
         return (m_scalpingMode == SCALPING_REVERSAL_ONLY);
         
      case 3: // Range
         return (m_scalpingMode == SCALPING_RANGE_ONLY);
         
      default:
         return false;
   }
}

//+------------------------------------------------------------------+
//| TREND FOLLOWING STRATEGIES                                        |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsTrendFollowingBuySignal() {
   // Get current market structure
   ENUM_MARKET_STRUCTURE structure = m_marketStructure.GetMarketStructure();
   
   // Only trade in uptrend markets
   if(structure != MARKET_STRONG_UPTREND && structure != MARKET_WEAK_UPTREND)
      return false;
      
   // Get Hurst info to check if suitable for trend following
   HurstInfo hurstInfo = m_marketStructure.GetHurstInfo();
   if(hurstInfo.value < 0.52 || hurstInfo.reliability < 60)
      return false;
   
   // Check EMA alignment for uptrend
   double emaFast = m_marketStructure.GetEMAFast();
   double emaMedium = m_marketStructure.GetEMAMedium();
   double emaLong = m_marketStructure.GetEMALong();
   
   if(!(emaFast > emaMedium && emaMedium > emaLong))
      return false;
      
   // Check for pullback to buy
   double rsi = m_marketStructure.GetRSI();
   if(rsi < 40 || rsi > 70) // Buy on pullback, not overbought
      return false;
   
   // Check if price is near a smaller EMA after pullback
   double emaScalp = iMA(m_symbol, m_timeframe, m_emaScalpPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double close = iClose(m_symbol, m_timeframe, 0);
   double atr = m_marketStructure.GetATR();
   
   if(MathAbs(close - emaScalp) > atr * 0.5)
      return false;
   
   // Check for crossover if enabled
   if(m_useEMACrossover && !IsEMACrossUp())
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Trend Following Sell Signal                                       |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsTrendFollowingSellSignal() {
   // Get current market structure
   ENUM_MARKET_STRUCTURE structure = m_marketStructure.GetMarketStructure();
   
   // Only trade in downtrend markets
   if(structure != MARKET_STRONG_DOWNTREND && structure != MARKET_WEAK_DOWNTREND)
      return false;
      
   // Get Hurst info to check if suitable for trend following
   HurstInfo hurstInfo = m_marketStructure.GetHurstInfo();
   if(hurstInfo.value < 0.52 || hurstInfo.reliability < 60)
      return false;
   
   // Check EMA alignment for downtrend
   double emaFast = m_marketStructure.GetEMAFast();
   double emaMedium = m_marketStructure.GetEMAMedium();
   double emaLong = m_marketStructure.GetEMALong();
   
   if(!(emaFast < emaMedium && emaMedium < emaLong))
      return false;
      
   // Check for pullback to sell
   double rsi = m_marketStructure.GetRSI();
   if(rsi > 60 || rsi < 30) // Sell on pullback, not oversold
      return false;
   
   // Check if price is near a smaller EMA after pullback
   double emaScalp = iMA(m_symbol, m_timeframe, m_emaScalpPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double close = iClose(m_symbol, m_timeframe, 0);
   double atr = m_marketStructure.GetATR();
   
   if(MathAbs(close - emaScalp) > atr * 0.5)
      return false;
   
   // Check for crossover if enabled
   if(m_useEMACrossover && !IsEMACrossDown())
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| REVERSAL STRATEGIES                                               |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsReversalBuySignal() {
   // Suitable for mean-reversion in downtrends or oversold conditions
   
   // Get current market structure
   ENUM_MARKET_STRUCTURE structure = m_marketStructure.GetMarketStructure();
   
   // Only allow in specific structures
   if(structure != MARKET_WEAK_DOWNTREND && 
      structure != MARKET_RANGING && 
      structure != MARKET_CHOPPY)
      return false;
   
   // Get Hurst info to check if suitable for mean reversion
   HurstInfo hurstInfo = m_marketStructure.GetHurstInfo();
   if(hurstInfo.value > 0.55 || hurstInfo.reliability < 60)
      return false;
   
   // Check for oversold condition
   if(m_marketStructure.IsOversold() == false)
      return false;
      
   // Check for bullish divergence or candlestick pattern
   if(!IsBullishDivergence(20) && !IsBullishEngulfing() && !IsMorningStar())
      return false;
   
   // Check for Stochastic crossover
   if(!IsStochasticCrossUp())
      return false;
      
   return true;
}

//+------------------------------------------------------------------+
//| Reversal Sell Signal                                              |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsReversalSellSignal() {
   // Suitable for mean-reversion in uptrends or overbought conditions
   
   // Get current market structure
   ENUM_MARKET_STRUCTURE structure = m_marketStructure.GetMarketStructure();
   
   // Only allow in specific structures
   if(structure != MARKET_WEAK_UPTREND && 
      structure != MARKET_RANGING && 
      structure != MARKET_CHOPPY)
      return false;
   
   // Get Hurst info to check if suitable for mean reversion
   HurstInfo hurstInfo = m_marketStructure.GetHurstInfo();
   if(hurstInfo.value > 0.55 || hurstInfo.reliability < 60)
      return false;
   
   // Check for overbought condition
   if(m_marketStructure.IsOverbought() == false)
      return false;
      
   // Check for bearish divergence or candlestick pattern
   if(!IsBearishDivergence(20) && !IsBearishEngulfing() && !IsEveningStar())
      return false;
   
   // Check for Stochastic crossover
   if(!IsStochasticCrossDown())
      return false;
      
   return true;
}

//+------------------------------------------------------------------+
//| RANGE STRATEGIES                                                 |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsRangeBuySignal() {
   // Get current market structure
   ENUM_MARKET_STRUCTURE structure = m_marketStructure.GetMarketStructure();
   
   // Only allow in ranging markets
   if(structure != MARKET_RANGING)
      return false;
   
   // Check if price is near lower Bollinger Band
   double close = iClose(m_symbol, m_timeframe, 0);
   double bollLower = iBands(m_symbol, m_timeframe, 20, 2.0, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double bollMiddle = iBands(m_symbol, m_timeframe, 20, 2.0, 0, PRICE_CLOSE, MODE_MAIN, 0);
   
   if(close > bollLower * 1.01) // Not close enough to lower band
      return false;
   
   // Check RSI is oversold but turning up
   double rsi = m_marketStructure.GetRSI();
   double rsiPrev = iRSI(m_symbol, m_timeframe, 14, PRICE_CLOSE, 1);
   
   if(rsi > 40 || rsi <= rsiPrev) // Not oversold or not turning up
      return false;
   
   // Check if Stochastic is oversold and turning up
   double stochK = m_marketStructure.GetStochK();
   double stochD = m_marketStructure.GetStochD();
   double stochKPrev = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_MAIN, 1);
   
   if(stochK > 30 || stochK <= stochKPrev) // Not oversold or not turning up
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Range Sell Signal                                                 |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsRangeSellSignal() {
   // Get current market structure
   ENUM_MARKET_STRUCTURE structure = m_marketStructure.GetMarketStructure();
   
   // Only allow in ranging markets
   if(structure != MARKET_RANGING)
      return false;
   
   // Check if price is near upper Bollinger Band
   double close = iClose(m_symbol, m_timeframe, 0);
   double bollUpper = iBands(m_symbol, m_timeframe, 20, 2.0, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bollMiddle = iBands(m_symbol, m_timeframe, 20, 2.0, 0, PRICE_CLOSE, MODE_MAIN, 0);
   
   if(close < bollUpper * 0.99) // Not close enough to upper band
      return false;
   
   // Check RSI is overbought but turning down
   double rsi = m_marketStructure.GetRSI();
   double rsiPrev = iRSI(m_symbol, m_timeframe, 14, PRICE_CLOSE, 1);
   
   if(rsi < 60 || rsi >= rsiPrev) // Not overbought or not turning down
      return false;
   
   // Check if Stochastic is overbought and turning down
   double stochK = m_marketStructure.GetStochK();
   double stochD = m_marketStructure.GetStochD();
   double stochKPrev = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_MAIN, 1);
   
   if(stochK < 70 || stochK >= stochKPrev) // Not overbought or not turning down
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check for EMA crossover up                                        |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsEMACrossUp() {
   // Check if fast EMA crossed above medium EMA
   double emaFast = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaFastPrev = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   
   double emaMedium = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaMediumPrev = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   
   return (emaFastPrev < emaMediumPrev && emaFast > emaMedium);
}

//+------------------------------------------------------------------+
//| Check for EMA crossover down                                      |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsEMACrossDown() {
   // Check if fast EMA crossed below medium EMA
   double emaFast = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaFastPrev = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   
   double emaMedium = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaMediumPrev = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   
   return (emaFastPrev > emaMediumPrev && emaFast < emaMedium);
}

//+------------------------------------------------------------------+
//| Check for Stochastic crossover up                                 |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsStochasticCrossUp() {
   double stochK = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_MAIN, 0);
   double stochD = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_SIGNAL, 0);
   
   double stochKPrev = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_MAIN, 1);
   double stochDPrev = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_SIGNAL, 1);
   
   return (stochKPrev < stochDPrev && stochK > stochD);
}

//+------------------------------------------------------------------+
//| Check for Stochastic crossover down                               |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsStochasticCrossDown() {
   double stochK = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_MAIN, 0);
   double stochD = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_SIGNAL, 0);
   
   double stochKPrev = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_MAIN, 1);
   double stochDPrev = iStochastic(m_symbol, m_timeframe, m_stochK, m_stochD, m_stochSlowing, MODE_SMA, 0, MODE_SIGNAL, 1);
   
   return (stochKPrev > stochDPrev && stochK < stochD);
}

//+------------------------------------------------------------------+
//| Check for bullish divergence                                      |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsBullishDivergence(int lookbackBars) {
   return m_marketStructure.IsPotentialReversal();
}

//+------------------------------------------------------------------+
//| Check for bearish divergence                                      |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsBearishDivergence(int lookbackBars) {
   return m_marketStructure.IsPotentialReversal();
}

//+------------------------------------------------------------------+
//| Check for bullish engulfing pattern                               |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsBullishEngulfing() {
   // Look for bullish engulfing pattern
   double open0 = iOpen(m_symbol, m_timeframe, 0);
   double close0 = iClose(m_symbol, m_timeframe, 0);
   double open1 = iOpen(m_symbol, m_timeframe, 1);
   double close1 = iClose(m_symbol, m_timeframe, 1);
   
   return (close1 < open1) && // Previous candle is bearish
          (close0 > open0) && // Current candle is bullish
          (open0 < close1) && // Current open below previous close
          (close0 > open1);   // Current close above previous open
}

//+------------------------------------------------------------------+
//| Check for bearish engulfing pattern                               |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsBearishEngulfing() {
   // Look for bearish engulfing pattern
   double open0 = iOpen(m_symbol, m_timeframe, 0);
   double close0 = iClose(m_symbol, m_timeframe, 0);
   double open1 = iOpen(m_symbol, m_timeframe, 1);
   double close1 = iClose(m_symbol, m_timeframe, 1);
   
   return (close1 > open1) && // Previous candle is bullish
          (close0 < open0) && // Current candle is bearish
          (open0 > close1) && // Current open above previous close
          (close0 < open1);   // Current close below previous open
}

//+------------------------------------------------------------------+
//| Check for morning star pattern                                    |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsMorningStar() {
   // Simplified morning star pattern check
   if(!IsBearishCandle(2))  // First candle bearish
      return false;
      
   if(!IsDoji(1))           // Middle candle small/doji
      return false;
      
   if(!IsBullishCandle(0))  // Last candle bullish
      return false;
      
   double body0 = MathAbs(iClose(m_symbol, m_timeframe, 0) - iOpen(m_symbol, m_timeframe, 0));
   double body2 = MathAbs(iClose(m_symbol, m_timeframe, 2) - iOpen(m_symbol, m_timeframe, 2));
   
   if(body0 < body2 * 0.5)  // Last candle should be significant
      return false;
      
   return true;
}

//+------------------------------------------------------------------+
//| Check for evening star pattern                                    |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsEveningStar() {
   // Simplified evening star pattern check
   if(!IsBullishCandle(2))  // First candle bullish
      return false;
      
   if(!IsDoji(1))           // Middle candle small/doji
      return false;
      
   if(!IsBearishCandle(0))  // Last candle bearish
      return false;
      
   double body0 = MathAbs(iClose(m_symbol, m_timeframe, 0) - iOpen(m_symbol, m_timeframe, 0));
   double body2 = MathAbs(iClose(m_symbol, m_timeframe, 2) - iOpen(m_symbol, m_timeframe, 2));
   
   if(body0 < body2 * 0.5)  // Last candle should be significant
      return false;
      
   return true;
}

//+------------------------------------------------------------------+
//| Check if candle is a Doji                                         |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsDoji(int barIndex) {
   double open = iOpen(m_symbol, m_timeframe, barIndex);
   double close = iClose(m_symbol, m_timeframe, barIndex);
   double high = iHigh(m_symbol, m_timeframe, barIndex);
   double low = iLow(m_symbol, m_timeframe, barIndex);
   
   double bodySize = MathAbs(open - close);
   double totalRange = high - low;
   
   // Body is small compared to total range
   return (totalRange > 0 && bodySize / totalRange < 0.2);
}

//+------------------------------------------------------------------+
//| Check if candle is bullish                                        |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsBullishCandle(int barIndex) {
   return iClose(m_symbol, m_timeframe, barIndex) > iOpen(m_symbol, m_timeframe, barIndex);
}

//+------------------------------------------------------------------+
//| Check if candle is bearish                                        |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsBearishCandle(int barIndex) {
   return iClose(m_symbol, m_timeframe, barIndex) < iOpen(m_symbol, m_timeframe, barIndex);
}

//+------------------------------------------------------------------+
//| Get string description of last signal                             |
//+------------------------------------------------------------------+
string CSignalGenerator::GetLastSignalDescription() const {
   if(m_lastSignalDirection == 0)
      return "No Signal";
      
   string direction = (m_lastSignalDirection == 1) ? "Buy" : "Sell";
   
   return direction + " signal generated at " + TimeToString(m_lastSignalTime);
}

//+------------------------------------------------------------------+
//| Check if there are any potential signals coming                   |
//+------------------------------------------------------------------+
bool CSignalGenerator::HasPotentialSignals(int direction) {
   // This is a simplified check for potential signals
   // In a real system, we would look at pre-conditions for signals
   
   // Trend following
   if(direction == 1) {
      // For buy signals
      if(m_marketStructure.GetRSI() < 50 && m_marketStructure.GetRSI() > 30)
         return true;
      
      if(m_marketStructure.GetStochK() < 50 && m_marketStructure.GetStochK() > 20)
         return true;
   }
   else if(direction == -1) {
      // For sell signals
      if(m_marketStructure.GetRSI() > 50 && m_marketStructure.GetRSI() < 70)
         return true;
      
      if(m_marketStructure.GetStochK() > 50 && m_marketStructure.GetStochK() < 80)
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Đánh giá tín hiệu từ phân tích Hurst                              |
//+------------------------------------------------------------------+
void CSignalGenerator::EvaluateHurstAnalysis()
{
   if(m_marketStructure == NULL || m_confirmationMatrix == NULL)
      return;
   
   // Lấy thông tin Hurst đa tầng
   double shortTermHurst = m_marketStructure.GetShortTermHurst();
   double mediumTermHurst = m_marketStructure.GetMediumTermHurst();
   double longTermHurst = m_marketStructure.GetLongTermHurst();
   bool hurstBullishDivergence = m_marketStructure.IsHurstBullishDivergence();
   bool hurstBearishDivergence = m_marketStructure.IsHurstBearishDivergence();
   bool hurstAlignedTrend = m_marketStructure.IsHurstAlignedForTrend();
   bool hurstAlignedReversal = m_marketStructure.IsHurstAlignedForReversal();
   double regimeChangeProb = m_marketStructure.GetRegimeChangeProbability();
   
   // Mô tả dựa trên phân tích Hurst
   string desc = "";
   double score = 0.0;
   
   // Xu hướng mạnh khi long-term và medium-term Hurst > 0.55
   if(longTermHurst > 0.55 && mediumTermHurst > 0.55) {
      // Tín hiệu mua
      if(m_marketStructure.IsBullishTrend()) {
         score = 1.5;
         desc = "Strong uptrend potential based on long-term Hurst (" + DoubleToString(longTermHurst, 2) + ")";
         
         // Đồng bộ các khung thời gian càng tốt
         if(hurstAlignedTrend)
            score += 0.5;
      }
      // Tín hiệu bán
      else if(m_marketStructure.IsBearishTrend()) {
         score = -1.5;
         desc = "Strong downtrend potential based on long-term Hurst (" + DoubleToString(longTermHurst, 2) + ")";
         
         // Đồng bộ các khung thời gian càng tốt
         if(hurstAlignedTrend)
            score -= 0.5;
      }
   }
   
   // Mean-reverting markets with Hurst < 0.45 
   else if(longTermHurst < 0.45) {
      // Tín hiệu mua (phản xu hướng)
      if(shortTermHurst < 0.42 && m_marketStructure.GetRSI() < 30) {
         score = 1.0;
         desc = "Mean-reversion buy signal with Hurst (" + DoubleToString(shortTermHurst, 2) + ")";
         
         // Sự đồng thuận đảo chiều
         if(hurstAlignedReversal)
            score += 0.5;
      }
      // Tín hiệu bán (phản xu hướng)
      else if(shortTermHurst < 0.42 && m_marketStructure.GetRSI() > 70) {
         score = -1.0;
         desc = "Mean-reversion sell signal with Hurst (" + DoubleToString(shortTermHurst, 2) + ")";
         
         // Sự đồng thuận đảo chiều
         if(hurstAlignedReversal)
            score -= 0.5;
      }
   }
   
   // Phát hiện phân kỳ Hurst - dấu hiệu đảo chiều
   if(hurstBullishDivergence) {
      score += 0.75;
      desc += (desc != "" ? ", " : "") + "Bullish Hurst divergence detected";
   }
   else if(hurstBearishDivergence) {
      score -= 0.75;
      desc += (desc != "" ? ", " : "") + "Bearish Hurst divergence detected";
   }
   
   // Xem xét xác suất thay đổi chế độ thị trường
   if(regimeChangeProb > 0.7) {
      desc += (desc != "" ? ", " : "") + "High probability of market regime change (" + DoubleToString(regimeChangeProb * 100, 0) + "%)";
      
      // Giảm điểm số khi có khả năng thay đổi chế độ
      score *= (1.0 - (regimeChangeProb - 0.7));
   }
   
   // Cập nhật ma trận xác nhận
   m_confirmationMatrix.SetHurstScore(score, desc);
}

//+------------------------------------------------------------------+
//| Đánh giá tín hiệu từ mô hình giá                                 |
//+------------------------------------------------------------------+
void CSignalGenerator::EvaluatePricePatterns(ENUM_TRIANGLE_TYPE triangleType, bool breakoutDetected) {
   if(m_marketStructure == NULL || m_confirmationMatrix == NULL)
      return;
   
   // Lấy thông tin về mô hình nến
   ENUM_CANDLE_PATTERN candlePattern = m_marketStructure.GetLastPattern().candlePattern;
   PatternInfo patternInfo = m_marketStructure.GetLastPattern();
   int patternStrength = patternInfo.patternStrength;
   int patternDirection = patternInfo.patternDirection;
   
   // Lấy thông tin về mô hình Wyckoff
   ENUM_WYCKOFF_PHASE wyckoffPhase = m_marketStructure.GetLastPattern().wyckoffPhase;
   bool hasSpring = m_marketStructure.HasSpringPattern();
   bool hasUpthrust = m_marketStructure.HasUpthrustPattern();
   
   // Kiểm tra nếu có các mẫu hình đặc biệt
   bool inAccumulation = m_marketStructure.IsInAccumulationPhase();
   bool inDistribution = m_marketStructure.IsInDistributionPhase();
   bool inMarkup = m_marketStructure.IsInMarkupPhase();
   bool inMarkdown = m_marketStructure.IsInMarkdownPhase();
   
   // Kiểm tra cấu trúc thị trường
   bool hasHigherHighsHigherLows = m_marketStructure.HasHigherHighsHigherLows();
   bool hasLowerLowsLowerHighs = m_marketStructure.HasLowerLowsLowerHighs();
   
   double score = 0.0;
   string desc = "";
   
   // Mẫu hình tam giác và breakout
   if(triangleType != TRIANGLE_NONE) {
      switch(triangleType) {
         case TRIANGLE_ASCENDING:
            score += 0.75;
            desc = "Ascending Triangle";
            break;
         
         case TRIANGLE_DESCENDING:
            score -= 0.75;
            desc = "Descending Triangle";
            break;
         
         case TRIANGLE_SYMMETRICAL:
            // Tam giác đối xứng - có thể đi lên hoặc xuống
            if(breakoutDetected) {
               // Kiểm tra hướng breakout
               bool isBullish = false;
               if(m_marketStructure.CheckPatternBreakout(isBullish)) {
                  if(isBullish) {
                     score += 1.0;
                     desc = "Symmetrical Triangle Bullish Breakout";
                  } else {
                     score -= 1.0;
                     desc = "Symmetrical Triangle Bearish Breakout";
                  }
               }
            } else {
               desc = "Symmetrical Triangle Formation";
            }
            break;
      }
   }
   
   // Mẫu hình nến
   if(candlePattern != PATTERN_NONE) {
      switch(candlePattern) {
         // Mẫu hình tăng
         case PATTERN_BULLISH_ENGULFING:
         case PATTERN_MORNING_STAR:
         case PATTERN_HAMMER:
            score += 0.5;
            desc += (desc != "" ? ", " : "") + patternInfo.patternDescription;
            break;
            
         // Mẫu hình giảm
         case PATTERN_BEARISH_ENGULFING:
         case PATTERN_EVENING_STAR:
         case PATTERN_SHOOTING_STAR:
            score -= 0.5;
            desc += (desc != "" ? ", " : "") + patternInfo.patternDescription;
            break;
            
         // Pin bar - tùy theo hướng
         case PATTERN_PINBAR:
            if(patternDirection > 0) {
               score += 0.5;
               desc += (desc != "" ? ", " : "") + "Bullish Pin Bar";
            } else if(patternDirection < 0) {
               score -= 0.5;
               desc += (desc != "" ? ", " : "") + "Bearish Pin Bar";
            }
            break;
            
         // Doji - thường là tín hiệu đảo chiều
         case PATTERN_DOJI:
            if(m_marketStructure.GetBias() > 0) {
               score -= 0.3; // Doji trong xu hướng tăng - có thể đảo chiều xuống
               desc += (desc != "" ? ", " : "") + "Doji in Uptrend";
            } else if(m_marketStructure.GetBias() < 0) {
               score += 0.3; // Doji trong xu hướng giảm - có thể đảo chiều lên
               desc += (desc != "" ? ", " : "") + "Doji in Downtrend";
            }
            break;
      }
   }
   
   // Đánh giá mẫu hình Wyckoff
   if(wyckoffPhase != WYCKOFF_NONE) {
      switch(wyckoffPhase) {
         case WYCKOFF_ACCUMULATION:
            score += 0.7;
            desc += (desc != "" ? ", " : "") + "Wyckoff Accumulation Phase";
            break;
            
         case WYCKOFF_DISTRIBUTION:
            score -= 0.7;
            desc += (desc != "" ? ", " : "") + "Wyckoff Distribution Phase";
            break;
            
         case WYCKOFF_MARKUP:
            score += 1.0;
            desc += (desc != "" ? ", " : "") + "Wyckoff Markup Phase";
            break;
            
         case WYCKOFF_MARKDOWN:
            score -= 1.0;
            desc += (desc != "" ? ", " : "") + "Wyckoff Markdown Phase";
            break;
      }
   }
   
   // Mẫu hình Spring/Upthrust trong phân tích Wyckoff
   if(hasSpring) {
      score += 1.0;
      desc += (desc != "" ? ", " : "") + "Wyckoff Spring Pattern (Bullish)";
   }
   
   if(hasUpthrust) {
      score -= 1.0;
      desc += (desc != "" ? ", " : "") + "Wyckoff Upthrust Pattern (Bearish)";
   }
   
   // Xét cấu trúc thị trường
   if(hasHigherHighsHigherLows) {
      score += 0.5;
      desc += (desc != "" ? ", " : "") + "Higher Highs & Higher Lows (Bullish)";
   }
   
   if(hasLowerLowsLowerHighs) {
      score -= 0.5;
      desc += (desc != "" ? ", " : "") + "Lower Lows & Lower Highs (Bearish)";
   }
   
   // Cập nhật ma trận xác nhận
   m_confirmationMatrix.SetPatternScore(score, desc);
}

//+------------------------------------------------------------------+
//| Đánh giá trendline                                             |
//+------------------------------------------------------------------+
void CSignalGenerator::EvaluateTrendlines(bool supportNearby, bool resistanceNearby, bool hasValidChannel)
{
   double score = 0.0;
   string desc = "";
   
   if(hasValidChannel)
     {
      score = 7.5;
      desc = "Kênh giá hợp lệ, thị trường có cấu trúc";
      
      if(supportNearby)
        {
         score += 1.5;
         desc += ", giá gần support";
        }
      else if(resistanceNearby)
        {
         score += 1.5;
         desc += ", giá gần resistance";
        }
     }
   else
     {
      score = 4.0;
      desc = "Không phát hiện kênh giá rõ ràng";
      
      if(supportNearby)
        {
         score += 3.0;
         desc += ", nhưng giá gần support";
        }
      else if(resistanceNearby)
        {
         score += 3.0;
         desc += ", nhưng giá gần resistance";
        }
     }
   
   // Giới hạn điểm trong khoảng 0-10
   score = MathMax(0, MathMin(10, score));
   
   // Đặt điểm cho trendline
   m_confirmationMatrix.SetTrendlineScore(score, desc);
}

//+------------------------------------------------------------------+
//| Đánh giá RSI                                                   |
//+------------------------------------------------------------------+
void CSignalGenerator::EvaluateRSI(double rsi, double rsiPrev, bool bullDivergence, bool bearDivergence, MultiTimeframeRSI mtfRsi, bool rsiValid)
{
   double score = 0.0;
   string desc = "";
   
   // Kiểm tra phân kỳ
   if(bullDivergence)
     {
      score = 8.0;
      desc = "RSI phân kỳ tăng";
      
      // Tăng điểm nếu các khung thời gian khác nhau cũng đồng thuận
      if(mtfRsi.aligned && mtfRsi.current < 30 && mtfRsi.higher < 50)
        {
         score += 1.5;
         desc += ", đồng thuận đa khung";
        }
     }
   else if(bearDivergence)
     {
      score = 8.0;
      desc = "RSI phân kỳ giảm";
      
      // Tăng điểm nếu các khung thời gian khác nhau cũng đồng thuận
      if(mtfRsi.aligned && mtfRsi.current > 70 && mtfRsi.higher > 50)
        {
         score += 1.5;
         desc += ", đồng thuận đa khung";
        }
     }
   else if(rsi < 30 || rsi > 70)
     {
      // RSI ở vùng quá mua/quá bán
      score = 6.0;
      
      if(rsi < 30)
         desc = StringFormat("RSI quá bán (%.1f)", rsi);
      else
         desc = StringFormat("RSI quá mua (%.1f)", rsi);
         
      // Thêm điểm nếu RSI đang dần hồi phục từ vùng cực đoan
      if((rsi < 30 && rsi > rsiPrev) || (rsi > 70 && rsi < rsiPrev))
        {
         score += 1.5;
         desc += ", đang hồi phục";
        }
     }
   else
     {
      // RSI ở vùng trung tính
      score = 3.0;
      desc = StringFormat("RSI trung tính (%.1f)", rsi);
     }
   
   // Trừ điểm nếu tín hiệu RSI không hợp lệ theo chế độ thị trường
   if(!rsiValid)
     {
      score *= 0.7;
      desc += ", không phù hợp với chế độ thị trường";
     }
   
   // Giới hạn điểm trong khoảng 0-10
   score = MathMax(0, MathMin(10, score));
   
   // Đặt điểm cho RSI
   m_confirmationMatrix.SetRSIScore(score, desc);
}

//+------------------------------------------------------------------+
//| Đánh giá SMC (Smart Money Concept)                                |
//+------------------------------------------------------------------+
void CSignalGenerator::EvaluateSMC()
{
   double score = 0.0;
   string desc = "";
   
   // Kiểm tra các cấu trúc SMC
   if(m_marketStructure.HasUnmitigatedOrderBlock())
     {
      score = 7.5;
      desc = "Order block chưa được xử lý";
      
      if(m_marketStructure.HasBullishOrderFlow())
        {
         score += 1.5;
         desc += ", dòng lệnh tăng";
        }
      else if(m_marketStructure.HasBearishOrderFlow())
        {
         score += 1.5;
         desc += ", dòng lệnh giảm";
        }
     }
   else if(m_marketStructure.HasFairValueGap())
     {
      score = 6.0;
      desc = "Fair value gap";
     }
   else if(m_marketStructure.HasLiquidityGrab())
     {
      score = 8.0;
      desc = "Liquidity grab, kỳ vọng đảo chiều";
     }
   else
     {
      score = 3.0;
      desc = "Không phát hiện cấu trúc SMC rõ ràng";
     }
   
   // Giới hạn điểm trong khoảng 0-10
   score = MathMax(0, MathMin(10, score));
   
   // Đặt điểm cho SMC
   m_confirmationMatrix.SetSMCScore(score, desc);
}

//+------------------------------------------------------------------+
//| Đánh giá ICP (Internal Market Structure)                           |
//+------------------------------------------------------------------+
void CSignalGenerator::EvaluateICP()
{
   double score = 0.0;
   string desc = "";
   
   // Kiểm tra cấu trúc nội tại
   if(m_marketStructure.HasHigherHighsHigherLows())
     {
      score = 8.0;
      desc = "Cấu trúc xu hướng tăng (HH-HL)";
     }
   else if(m_marketStructure.HasLowerLowsLowerHighs())
     {
      score = 8.0;
      desc = "Cấu trúc xu hướng giảm (LL-LH)";
     }
   else if(m_marketStructure.HasBrokenMarketStructure())
     {
      score = 7.0;
      desc = "Cấu trúc thị trường bị phá vỡ";
     }
   else
     {
      score = 4.0;
      desc = "Cấu trúc thị trường không rõ ràng";
     }
   
   // Giới hạn điểm trong khoảng 0-10
   score = MathMax(0, MathMin(10, score));
   
   // Đặt điểm cho ICP
   m_confirmationMatrix.SetICPScore(score, desc);
}

//+------------------------------------------------------------------+
//| Đánh giá phân tích Wyckoff                                       |
//+------------------------------------------------------------------+
void CSignalGenerator::EvaluateWyckoff()
{
   double score = 0.0;
   string desc = "";
   
   // Kiểm tra các giai đoạn Wyckoff
   if(m_marketStructure.IsInAccumulationPhase())
     {
      score = 6.5;
      desc = "Giai đoạn tích lũy Wyckoff";
      
      if(m_marketStructure.HasSpringPattern())
        {
         score += 2.5;
         desc += ", phát hiện Spring";
        }
     }
   else if(m_marketStructure.IsInDistributionPhase())
     {
      score = 6.5;
      desc = "Giai đoạn phân phối Wyckoff";
      
      if(m_marketStructure.HasUpthrustPattern())
        {
         score += 2.5;
         desc += ", phát hiện Upthrust";
        }
     }
   else if(m_marketStructure.IsInMarkupPhase())
     {
      score = 7.0;
      desc = "Giai đoạn tăng giá Wyckoff";
     }
   else if(m_marketStructure.IsInMarkdownPhase())
     {
      score = 7.0;
      desc = "Giai đoạn giảm giá Wyckoff";
     }
   else
     {
      score = 3.0;
      desc = "Không xác định được giai đoạn Wyckoff";
     }
   
   // Giới hạn điểm trong khoảng 0-10
   score = MathMax(0, MathMin(10, score));
   
   // Đặt điểm cho Wyckoff
   m_confirmationMatrix.SetWyckoffScore(score, desc);
}

//+------------------------------------------------------------------+
//| Xác định xem tín hiệu mua có chiếm ưu thế không                      |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsBuySignalDominant(SignalMatrix *matrix)
{
   if(matrix == NULL) return false;
   
   // Lấy thông tin Hurst đa tầng
   double shortTermHurst = m_marketStructure.GetShortTermHurst();
   double mediumTermHurst = m_marketStructure.GetMediumTermHurst();
   double longTermHurst = m_marketStructure.GetLongTermHurst();
   bool hurstAlignedTrend = m_marketStructure.IsHurstAlignedForTrend();
   bool hurstAlignedReversion = m_marketStructure.IsHurstAlignedForReversal();
   ENUM_MARKET_MODE marketMode = m_marketStructure.GetMarketMode();
   
   // Số lượng tín hiệu mua
   int buySignals = 0;
   
   // Kiểm tra từng thành phần của ma trận
   if(matrix.hurstScore > 0.3) buySignals++;
   if(matrix.patternScore > 0.4) buySignals++;
   if(matrix.trendlineScore > 0.4) buySignals++;
   if(matrix.smcScore > 0.3) buySignals++;
   if(matrix.icpScore > 0.3) buySignals++;
   if(matrix.wyckoffScore > 0.4) buySignals++;
   if(matrix.rsiScore > 0.3) buySignals++;
   
   // Xác định số lượng tối thiểu tín hiệu cần thiết dựa trên chế độ thị trường và Hurst
   int minRequiredSignals = 3; // Mặc định yêu cầu 3 tín hiệu
   
   // Trong thị trường trending với Hurst cao, cần ít tín hiệu xác nhận hơn
   if(marketMode == MARKET_MODE_TRENDING && longTermHurst > 0.6 && hurstAlignedTrend) {
      minRequiredSignals = 2;
   }
   // Trong thị trường ranging hoặc reversal, cần nhiều tín hiệu xác nhận hơn
   else if((marketMode == MARKET_MODE_RANGING || marketMode == MARKET_MODE_REVERSAL) && 
            !hurstAlignedTrend) {
      minRequiredSignals = 4;
   }
   // Trong thị trường volatile, cần nhiều tín hiệu xác nhận hơn nữa
   else if(marketMode == MARKET_MODE_VOLATILE) {
      minRequiredSignals = 5;
   }
   
   // Điều kiện bổ sung: Tín hiệu mua phải phù hợp với tiêu chí Hurst
   if(longTermHurst > 0.55 && matrix.hurstScore < 0) {
      // Mâu thuẫn: Hurst cho thấy xu hướng nhưng tín hiệu Hurst lại âm
      return false;
   }
   
   if(longTermHurst < 0.45 && matrix.rsiScore <= 0) {
      // Mâu thuẫn: Hurst cho thấy mean-reverting nhưng RSI không hỗ trợ
      return false;
   }
   
   // Đảm bảo tổng điểm là dương và đủ mạnh
   return matrix.totalScore > 0 && buySignals >= minRequiredSignals;
}

//+------------------------------------------------------------------+
//| Xác định xem tín hiệu bán có chiếm ưu thế không                      |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsSellSignalDominant(SignalMatrix *matrix)
{
   if(matrix == NULL) return false;
   
   // Lấy thông tin Hurst đa tầng
   double shortTermHurst = m_marketStructure.GetShortTermHurst();
   double mediumTermHurst = m_marketStructure.GetMediumTermHurst();
   double longTermHurst = m_marketStructure.GetLongTermHurst();
   bool hurstAlignedTrend = m_marketStructure.IsHurstAlignedForTrend();
   bool hurstAlignedReversion = m_marketStructure.IsHurstAlignedForReversal();
   ENUM_MARKET_MODE marketMode = m_marketStructure.GetMarketMode();
   
   // Số lượng tín hiệu bán
   int sellSignals = 0;
   
   // Kiểm tra từng thành phần của ma trận
   if(matrix.hurstScore < -0.3) sellSignals++;
   if(matrix.patternScore < -0.4) sellSignals++;
   if(matrix.trendlineScore < -0.4) sellSignals++;
   if(matrix.smcScore < -0.3) sellSignals++;
   if(matrix.icpScore < -0.3) sellSignals++;
   if(matrix.wyckoffScore < -0.4) sellSignals++;
   if(matrix.rsiScore < -0.3) sellSignals++;
   
   // Xác định số lượng tối thiểu tín hiệu cần thiết dựa trên chế độ thị trường và Hurst
   int minRequiredSignals = 3; // Mặc định yêu cầu 3 tín hiệu
   
   // Trong thị trường trending với Hurst cao, cần ít tín hiệu xác nhận hơn
   if(marketMode == MARKET_MODE_TRENDING && longTermHurst > 0.6 && hurstAlignedTrend) {
      minRequiredSignals = 2;
   }
   // Trong thị trường ranging hoặc reversal, cần nhiều tín hiệu xác nhận hơn
   else if((marketMode == MARKET_MODE_RANGING || marketMode == MARKET_MODE_REVERSAL) && 
            !hurstAlignedTrend) {
      minRequiredSignals = 4;
   }
   // Trong thị trường volatile, cần nhiều tín hiệu xác nhận hơn nữa
   else if(marketMode == MARKET_MODE_VOLATILE) {
      minRequiredSignals = 5;
   }
   
   // Điều kiện bổ sung: Tín hiệu bán phải phù hợp với tiêu chí Hurst
   if(longTermHurst > 0.55 && matrix.hurstScore > 0) {
      // Mâu thuẫn: Hurst cho thấy xu hướng nhưng tín hiệu Hurst lại dương
      return false;
   }
   
   if(longTermHurst < 0.45 && matrix.rsiScore >= 0) {
      // Mâu thuẫn: Hurst cho thấy mean-reverting nhưng RSI không hỗ trợ
      return false;
   }
   
   // Đảm bảo tổng điểm là âm và đủ mạnh
   return matrix.totalScore < 0 && sellSignals >= minRequiredSignals;
} 