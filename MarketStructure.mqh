//+------------------------------------------------------------------+
//|                          MarketStructure.mqh                      |
//|                  Copyright 2025, Trading Systems Development       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Systems Development"
#property link      "https://www.mql5.com"

#include <Math/Stat/Math.mqh>
#include "../Utils/Common.mqh"
#include "HurstAnalysis.mqh"
// RSI Analysis is now integrated directly into this file

//+------------------------------------------------------------------+
//| Cấu trúc lưu thông tin trendline                                 |
//+------------------------------------------------------------------+
struct TrendlineInfo {
   datetime time1, time2;  // Thời gian hai điểm
   double price1, price2;  // Giá tương ứng
   int touchPoints;        // Số điểm chạm
   double strength;        // Độ mạnh (0-10)
   bool isValid;           // Hiệu lực
   datetime lastTouch;     // Lần chạm gần nhất
};

//+------------------------------------------------------------------+
//| Định nghĩa enum cho các loại tam giác                            |
//+------------------------------------------------------------------+
enum ENUM_TRIANGLE_TYPE {
   TRIANGLE_NONE,         // Không phát hiện tam giác
   TRIANGLE_SYMMETRICAL,  // Tam giác đối xứng
   TRIANGLE_ASCENDING,    // Tam giác tăng
   TRIANGLE_DESCENDING    // Tam giác giảm
};

//+------------------------------------------------------------------+
//| Enum cho các loại mô hình nến                                    |
//+------------------------------------------------------------------+
enum ENUM_CANDLE_PATTERN {
   PATTERN_NONE,              // Không có mô hình nào
   PATTERN_BULLISH_ENGULFING, // Mô hình bao phủ tăng
   PATTERN_BEARISH_ENGULFING, // Mô hình bao phủ giảm
   PATTERN_MORNING_STAR,      // Sao mai
   PATTERN_EVENING_STAR,      // Sao hôm
   PATTERN_HAMMER,            // Búa
   PATTERN_SHOOTING_STAR,     // Sao băng
   PATTERN_DOJI,              // Doji
   PATTERN_DRAGONFLY_DOJI,    // Doji chuồn chuồn
   PATTERN_GRAVESTONE_DOJI,   // Doji bia mộ
   PATTERN_HARAMI,            // Harami
   PATTERN_PINBAR              // Pin Bar
};

//+------------------------------------------------------------------+
//| Enum cho các loại mô hình giá Harmonics                          |
//+------------------------------------------------------------------+
enum ENUM_HARMONIC_PATTERN {
   HARMONIC_NONE,             // Không có mô hình nào
   HARMONIC_GARTLEY,          // Mô hình Gartley
   HARMONIC_BUTTERFLY,        // Mô hình Butterfly
   HARMONIC_BAT,              // Mô hình Bat
   HARMONIC_CRAB,             // Mô hình Crab
   HARMONIC_SHARK,            // Mô hình Shark
   HARMONIC_CYPHER            // Mô hình Cypher
};

//+------------------------------------------------------------------+
//| Enum cho các loại mô hình giá Wyckoff                           |
//+------------------------------------------------------------------+
enum ENUM_WYCKOFF_PHASE {
   WYCKOFF_NONE,              // Không có giai đoạn nào
   WYCKOFF_ACCUMULATION,      // Giai đoạn tích lũy
   WYCKOFF_MARKUP,            // Giai đoạn tăng
   WYCKOFF_DISTRIBUTION,      // Giai đoạn phân phối
   WYCKOFF_MARKDOWN           // Giai đoạn giảm
};

//+------------------------------------------------------------------+
//| Enum cho các loại mô hình giá Wyckoff                           |
//+------------------------------------------------------------------+
enum ENUM_MARKET_MODE {
   MARKET_MODE_UNKNOWN,       // Không xác định
   MARKET_MODE_TRENDING,      // Xu hướng
   MARKET_MODE_RANGING,       // Thị trường đi ngang
   MARKET_MODE_VOLATILE,      // Thị trường biến động
   MARKET_MODE_REVERSAL       // Có dấu hiệu đảo chiều
};

//+------------------------------------------------------------------+
//| Struct cho mô hình giá                                          |
//+------------------------------------------------------------------+
struct PatternInfo {
   ENUM_CANDLE_PATTERN candlePattern;      // Mô hình nến
   ENUM_HARMONIC_PATTERN harmonicPattern;  // Mô hình Harmonics
   ENUM_WYCKOFF_PHASE wyckoffPhase;        // Giai đoạn Wyckoff
   int patternStrength;                     // Độ mạnh mô hình (0-100)
   int patternDirection;                    // Hướng mô hình (1=lên, -1=xuống, 0=trung tính)
   string patternDescription;               // Mô tả mô hình
   datetime detectionTime;                  // Thời điểm phát hiện
};

//+------------------------------------------------------------------+
//| Class for Market Structure Analysis                              |
//+------------------------------------------------------------------+
class CMarketStructure {
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   
   // Technical indicator variables
   double m_atr;
   double m_adx;
   double m_rsi;
   double m_stochK;
   double m_stochD;
   double m_emaFast;
   double m_emaMedium;
   double m_emaLong;
   double m_bollUpper;
   double m_bollMiddle;
   double m_bollLower;
   
   // Indicator settings
   int m_rsiPeriod;
   int m_adxPeriod;
   double m_adxThreshold;
   int m_stochKPeriod;
   int m_stochDPeriod;
   int m_stochSlowing;
   double m_stochUpperLevel;
   double m_stochLowerLevel;
   int m_emaFastPeriod;
   int m_emaMediumPeriod;
   int m_emaLongPeriod;
   int m_bollPeriod;
   double m_bollDeviation;
   int m_atrPeriod;
   
   // Volatility and trend variables
   double m_volatility;
   bool m_isHighVolatility;
   bool m_isVolatilityIncreasing;
   double m_volatilityThreshold;
   double m_previousVolatility;
   double m_maxATRForNormalTrading;
   
   // Hurst Exponent integration
   CHurstAnalysis *m_hurstAnalysis;
   HurstInfo m_hurstInfo;
   double m_shortTermHurst;      // Ngắn hạn (200-300 nến) - điểm vào lệnh
   double m_mediumTermHurst;     // Trung hạn (500-600 nến) - chu kỳ swing
   double m_longTermHurst;       // Dài hạn (1000+ nến) - chế độ thị trường
   bool m_hurstDivergenceBullish;  // Phân kỳ tăng giá Hurst
   bool m_hurstDivergenceBearish;  // Phân kỳ giảm giá Hurst
   bool m_hurstAlignedTrending;    // Hurst đồng thuận xu hướng
   bool m_hurstAlignedReverting;   // Hurst đồng thuận đảo chiều
   double m_regimeChangeProbability; // Xác suất thay đổi chế độ thị trường
   
   // RSI Analysis integrated variables
   // RSI indicator handle
   int m_rsiHandle;
   double m_rsiPrev;
   double m_dynamicRSIOverbought;
   double m_dynamicRSIOversold;
   bool m_rsiBullDivergence;
   bool m_rsiBearDivergence;
   MultiTimeframeRSI m_mtfRsi;
   double m_rsiHurstAlignment;
   
   // RSI parameters as member variables
   double m_rsiOverbought;
   double m_rsiOversold;
   bool m_useAdaptiveRSI;
   bool m_useRSIDivergence;
   bool m_useMultiTimeframeRSI;
   
   // Trendline analysis
   TrendlineInfo m_upperTrendline;
   TrendlineInfo m_lowerTrendline;
   double m_upperChannel;
   double m_lowerChannel;
   double m_channelWidth;
   bool m_hasValidChannel;
   ENUM_TRIANGLE_TYPE m_triangleType;
   
   // Pattern recognition
   PatternInfo m_lastPattern;
   int m_candlePatternSensitivity;      // 1-10, higher = more sensitive
   int m_harmonicPatternSensitivity;    // 1-10
   int m_wyckoffSensitivity;            // 1-10
   bool m_hasSpringPattern;             // Wyckoff Spring pattern
   bool m_hasUpthrustPattern;           // Wyckoff Upthrust pattern
   ENUM_WYCKOFF_PHASE m_currentWyckoffPhase; // Current Wyckoff phase
   
   // Private methods
   bool IsTrending();
   bool IsRanging();
   bool IsVolatile();
   bool IsChoppy();
   double CalculateVolatility();
   void UpdateIndicators();
   bool IsBearishDivergence(int lookbackBars);
   bool IsBullishDivergence(int lookbackBars);
   bool IsBreakout();
   
   // RSI Analysis Private Helper Methods
   ENUM_TIMEFRAMES GetHigherTimeframe(ENUM_TIMEFRAMES tf);
   ENUM_TIMEFRAMES GetLowerTimeframe(ENUM_TIMEFRAMES tf);
   
   // Pattern Recognition Private Methods
   double CalculateFibonacciRatio(double move1, double move2);
   bool IsValidHarmonicPattern(double xabRatio, double abcRatio, double bcdRatio, double xadRatio);
   bool HasVolumeConfirmation(int shift, bool isUp);
   
   // Hurst Analysis Private Methods
   void UpdateMultiTimeframeHurst();
   
public:
   // Constructor
   CMarketStructure(
      string symbol,
      ENUM_TIMEFRAMES timeframe,
      int rsiPeriod = 14,
      int adxPeriod = 14,
      double adxThreshold = 20.0,
      int stochKPeriod = 5,
      int stochDPeriod = 3,
      int stochSlowing = 3,
      double stochUpperLevel = 80.0,
      double stochLowerLevel = 20.0,
      int emaFastPeriod = 21,
      int emaMediumPeriod = 50,
      int emaLongPeriod = 200,
      int bollPeriod = 20,
      double bollDeviation = 2.0,
      int atrPeriod = 14,
      double volatilityThreshold = 1.5,
      double maxATRForNormalTrading = 15.0,
      double rsiOverbought = 70.0,
      double rsiOversold = 30.0
   );
   
   // Destructor
   ~CMarketStructure();
   
   // Initialize Hurst Analysis
   void InitializeHurstAnalysis(
      int hurstPeriod,
      double hurstTrendThreshold,
      double hurstMeanRevThreshold
   );
   
   // Update market structure analysis
   ENUM_MARKET_STRUCTURE AnalyzeMarketStructure();
   
   // Get current market structure with integrated Hurst analysis
   ENUM_MARKET_STRUCTURE GetMarketStructure();
   
   // Get individual indicator values
   double GetADX() const { return m_adx; }
   double GetRSI() const { return m_rsi; }
   double GetATR() const { return m_atr; }
   double GetVolatility() const { return m_volatility; }
   double GetEMAFast() const { return m_emaFast; }
   double GetEMAMedium() const { return m_emaMedium; }
   double GetEMALong() const { return m_emaLong; }
   double GetStochK() const { return m_stochK; }
   double GetStochD() const { return m_stochD; }
   HurstInfo GetHurstInfo() const { return m_hurstInfo; }
   
   // Get trend strength (0-100)
   int GetTrendStrength();
   
   // Check volatility conditions
   bool IsHighVolatility() const { return m_isHighVolatility; }
   bool IsVolatilityIncreasing() const { return m_isVolatilityIncreasing; }
   
   // Check if price is in overbought/oversold condition
   bool IsOverbought();
   bool IsOversold();
   
   // Get current bias (1 = bullish, -1 = bearish, 0 = neutral)
   int GetBias();
   
   // Check for potential reversal
   bool IsPotentialReversal();
   
   // Get current volatility level compared to historical
   double GetVolatilityLevel();
   
   // Update settings
   void UpdateSettings(
      int rsiPeriod,
      int adxPeriod,
      double adxThreshold,
      int emaFastPeriod,
      int emaMediumPeriod,
      int emaLongPeriod
   );
   
   // RSI Analysis public methods
   void UpdateRSI();
   double CalculateRSI(int shift = 0);
   void GetDynamicRSILevels(double hurstValue, ENUM_MARKET_STRUCTURE marketStructure, double &overbought, double &oversold);
   bool DetectRSIDivergence(bool isBullish);
   MultiTimeframeRSI GetMultiTimeframeRSI();
   double GetRSIHurstAlignment(double rsiValue, double hurstValue);
   bool IsValidRSISignal(bool isBuy);
   
   // RSI getter methods
   double GetPreviousRSI() const { return m_rsiPrev; }
   double GetDynamicRSIOverbought() const { return m_dynamicRSIOverbought; }
   double GetDynamicRSIOversold() const { return m_dynamicRSIOversold; }
   bool IsRSIBullishDivergence() const { return m_rsiBullDivergence; }
   bool IsRSIBearishDivergence() const { return m_rsiBearDivergence; }
   double GetRSIHurstAlignment() const { return m_rsiHurstAlignment; }
   
   // Trendline analysis methods
   void IdentifyKeyTrendlines();
   double ValidateTrendline(TrendlineInfo &tl, bool isUpper, int maxBars = 300);
   void IdentifySwingHighsLows(int &highPoints[], int &lowPoints[], int &highCount, int &lowCount, int maxBars);
   double CalculateTrendlinePrice(const TrendlineInfo &tl, datetime time);
   bool DetectPriceChannel();
   ENUM_TRIANGLE_TYPE DetectTrianglePattern();
   bool IsSupportTrendlineNearby(int pipsThreshold = 20);
   bool IsResistanceTrendlineNearby(int pipsThreshold = 20);
   bool CheckPatternBreakout(bool &isBullish);
   
   // Getters for trendline data
   TrendlineInfo GetUpperTrendline() const { return m_upperTrendline; }
   TrendlineInfo GetLowerTrendline() const { return m_lowerTrendline; }
   double GetUpperChannel() const { return m_upperChannel; }
   double GetLowerChannel() const { return m_lowerChannel; }
   double GetChannelWidth() const { return m_channelWidth; }
   bool HasValidChannel() const { return m_hasValidChannel; }
   ENUM_TRIANGLE_TYPE GetTriangleType() const { return m_triangleType; }
   
   // Pattern Recognition Public Methods
   void UpdatePatternRecognition();
   ENUM_CANDLE_PATTERN DetectCandlePattern(int startBar = 0, int lookback = 5);
   ENUM_HARMONIC_PATTERN DetectHarmonicPattern(int lookback = 50);
   ENUM_WYCKOFF_PHASE DetectWyckoffPhase(int lookback = 100);
   
   // Check for specific candle patterns
   bool IsBullishEngulfing(int shift = 0);
   bool IsBearishEngulfing(int shift = 0);
   bool IsMorningStar(int shift = 0);
   bool IsEveningStar(int shift = 0);
   bool IsHammer(int shift = 0);
   bool IsShootingStar(int shift = 0);
   bool IsDoji(int shift = 0);
   bool IsPinBar(int shift = 0);
   
   // Wyckoff specific patterns
   bool HasSpringPattern() const { return m_hasSpringPattern; }
   bool HasUpthrustPattern() const { return m_hasUpthrustPattern; }
   bool IsInAccumulationPhase() const { return m_currentWyckoffPhase == WYCKOFF_ACCUMULATION; }
   bool IsInDistributionPhase() const { return m_currentWyckoffPhase == WYCKOFF_DISTRIBUTION; }
   bool IsInMarkupPhase() const { return m_currentWyckoffPhase == WYCKOFF_MARKUP; }
   bool IsInMarkdownPhase() const { return m_currentWyckoffPhase == WYCKOFF_MARKDOWN; }
   
   // General pattern methods
   bool IsBullishCandlePattern();
   bool IsBearishCandlePattern();
   
   // Get pattern information
   PatternInfo GetLastPattern() const { return m_lastPattern; }
   string GetPatternDescription() const { return m_lastPattern.patternDescription; }
   int GetPatternDirection() const { return m_lastPattern.patternDirection; }
   int GetPatternStrength() const { return m_lastPattern.patternStrength; }
   
   // Settings
   void SetPatternSensitivity(int candleSensitivity, int harmonicSensitivity, int wyckoffSensitivity);
   
   // Advanced Hurst Analysis methods
   void UpdateHurstAnalysis();
   double GetShortTermHurst() const { return m_shortTermHurst; }
   double GetMediumTermHurst() const { return m_mediumTermHurst; }
   double GetLongTermHurst() const { return m_longTermHurst; }
   bool IsHurstBullishDivergence() const { return m_hurstDivergenceBullish; }
   bool IsHurstBearishDivergence() const { return m_hurstDivergenceBearish; }
   bool IsHurstAlignedForTrend() const { return m_hurstAlignedTrending; }
   bool IsHurstAlignedForReversal() const { return m_hurstAlignedReverting; }
   double GetRegimeChangeProbability() const { return m_regimeChangeProbability; }
   bool IsBullishTrend() const;
   bool IsBearishTrend() const;
   
   // Phân tích chế độ thị trường                                       |
   //+------------------------------------------------------------------+
   ENUM_MARKET_MODE GetMarketMode();
   
   //+------------------------------------------------------------------+
   //| Kiểm tra xem có đột phá thị trường không                         |
   //+------------------------------------------------------------------+
   bool IsBreakout();
   
   //+------------------------------------------------------------------+
   //| Lấy giá trị Hurst Exponent hiện tại                              |
   //+------------------------------------------------------------------+
   double GetHurstExponent();
   
   // Các phương thức mô phỏng cho SMC (Smart Money Concept)
   bool HasUnmitigatedOrderBlock() const { return false; } // placeholder
   bool HasBullishOrderFlow() const { return false; } // placeholder
   bool HasBearishOrderFlow() const { return false; } // placeholder
   bool HasFairValueGap() const { return false; } // placeholder
   bool HasLiquidityGrab() const { return false; } // placeholder
   
   // Các phương thức mô phỏng cho ICP (Internal Market Structure)
   bool HasHigherHighsHigherLows() const;
   bool HasLowerLowsLowerHighs() const;
   bool HasBrokenMarketStructure() const { return false; } // placeholder
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CMarketStructure::CMarketStructure(
   string symbol,
   ENUM_TIMEFRAMES timeframe,
   int rsiPeriod,
   int adxPeriod,
   double adxThreshold,
   int stochKPeriod,
   int stochDPeriod,
   int stochSlowing,
   double stochUpperLevel,
   double stochLowerLevel,
   int emaFastPeriod,
   int emaMediumPeriod,
   int emaLongPeriod,
   int bollPeriod,
   double bollDeviation,
   int atrPeriod,
   double volatilityThreshold,
   double maxATRForNormalTrading,
   double rsiOverbought,
   double rsiOversold
) : m_symbol(symbol),
    m_timeframe(timeframe),
    m_rsiPeriod(rsiPeriod),
    m_adxPeriod(adxPeriod),
    m_adxThreshold(adxThreshold),
    m_stochKPeriod(stochKPeriod),
    m_stochDPeriod(stochDPeriod),
    m_stochSlowing(stochSlowing),
    m_stochUpperLevel(stochUpperLevel),
    m_stochLowerLevel(stochLowerLevel),
    m_emaFastPeriod(emaFastPeriod),
    m_emaMediumPeriod(emaMediumPeriod),
    m_emaLongPeriod(emaLongPeriod),
    m_bollPeriod(bollPeriod),
    m_bollDeviation(bollDeviation),
    m_atrPeriod(atrPeriod),
    m_volatilityThreshold(volatilityThreshold),
    m_maxATRForNormalTrading(maxATRForNormalTrading),
    m_rsiOverbought(rsiOverbought),
    m_rsiOversold(rsiOversold),
    m_useAdaptiveRSI(true),
    m_useRSIDivergence(true),
    m_useMultiTimeframeRSI(true),
    m_hurstAnalysis(NULL)
{
   // Initialize indicator values
   m_atr = 0;
   m_adx = 0;
   m_rsi = 50.0;
   m_stochK = 0;
   m_stochD = 0;
   m_emaFast = 0;
   m_emaMedium = 0;
   m_emaLong = 0;
   m_bollUpper = 0;
   m_bollMiddle = 0;
   m_bollLower = 0;
   
   // Initialize volatility tracking
   m_volatility = 0;
   m_isHighVolatility = false;
   m_isVolatilityIncreasing = false;
   m_previousVolatility = 0;
   
   // Initialize RSI parameters
   m_rsiPeriod = rsiPeriod;
   m_rsiOverbought = rsiOverbought;
   m_rsiOversold = rsiOversold;
   m_useAdaptiveRSI = true;
   m_useRSIDivergence = true;
   m_useMultiTimeframeRSI = true;

   // Initialize RSI handle
   m_rsiHandle = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE);
   
   if(m_rsiHandle == INVALID_HANDLE) {
      Print("Error: Failed to create RSI indicator handle");
   }

   m_rsiPrev = 50.0;
   m_dynamicRSIOverbought = m_rsiOverbought;
   m_dynamicRSIOversold = m_rsiOversold;
   m_rsiBullDivergence = false;
   m_rsiBearDivergence = false;
   m_rsiHurstAlignment = 50.0;
   
   // Initialize trendline analysis
   m_upperTrendline.isValid = false;
   m_lowerTrendline.isValid = false;
   m_upperChannel = 0;
   m_lowerChannel = 0;
   m_channelWidth = 0;
   m_hasValidChannel = false;
   m_triangleType = TRIANGLE_NONE;
   
   // Initialize pattern recognition
   m_lastPattern.candlePattern = PATTERN_NONE;
   m_lastPattern.harmonicPattern = HARMONIC_NONE;
   m_lastPattern.wyckoffPhase = WYCKOFF_NONE;
   m_lastPattern.patternStrength = 0;
   m_lastPattern.patternDirection = 0;
   m_lastPattern.patternDescription = "";
   m_lastPattern.detectionTime = 0;
   m_candlePatternSensitivity = 5;
   m_harmonicPatternSensitivity = 5;
   m_wyckoffSensitivity = 5;
   m_hasSpringPattern = false;
   m_hasUpthrustPattern = false;
   m_currentWyckoffPhase = WYCKOFF_NONE;
   
   // Update indicators on initialization
   UpdateIndicators();
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CMarketStructure::~CMarketStructure() {
   // Clean up Hurst analysis if initialized
   if(m_hurstAnalysis != NULL) {
      delete m_hurstAnalysis;
      m_hurstAnalysis = NULL;
   }
   
   // Release RSI indicator handle
   if(m_rsiHandle != INVALID_HANDLE) {
      IndicatorRelease(m_rsiHandle);
   }
}

//+------------------------------------------------------------------+
//| Get higher timeframe                                              |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CMarketStructure::GetHigherTimeframe(ENUM_TIMEFRAMES tf) {
   switch(tf) {
      case PERIOD_M1:  return PERIOD_M5;
      case PERIOD_M5:  return PERIOD_M15;
      case PERIOD_M15: return PERIOD_M30;
      case PERIOD_M30: return PERIOD_H1;
      case PERIOD_H1:  return PERIOD_H4;
      case PERIOD_H4:  return PERIOD_D1;
      default:         return PERIOD_D1;
   }
}

//+------------------------------------------------------------------+
//| Get lower timeframe                                               |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CMarketStructure::GetLowerTimeframe(ENUM_TIMEFRAMES tf) {
   switch(tf) {
      case PERIOD_M5:  return PERIOD_M1;
      case PERIOD_M15: return PERIOD_M5;
      case PERIOD_M30: return PERIOD_M15;
      case PERIOD_H1:  return PERIOD_M30;
      case PERIOD_H4:  return PERIOD_H1;
      case PERIOD_D1:  return PERIOD_H4;
      default:         return tf;
   }
}

//+------------------------------------------------------------------+
//| Calculate RSI value                                               |
//+------------------------------------------------------------------+
double CMarketStructure::CalculateRSI(int shift) {
   if(m_rsiHandle == INVALID_HANDLE) {
      return 50.0; // Neutral value on error
   }
   
   // Store previous RSI
   if(shift == 0) {
      double currentRSI = 50.0;
      double rsiBuffer[];
      
      if(CopyBuffer(m_rsiHandle, 0, shift, 1, rsiBuffer) == 1) {
         currentRSI = rsiBuffer[0];
         m_rsiPrev = currentRSI;
      }
      
      return currentRSI;
   }
   else {
      double rsiBuffer[];
      
      if(CopyBuffer(m_rsiHandle, 0, shift, 1, rsiBuffer) == 1) {
         return rsiBuffer[0];
      }
      
      return 50.0; // Neutral value on error
   }
}

//+------------------------------------------------------------------+
//| Update RSI values and analysis                                    |
//+------------------------------------------------------------------+
void CMarketStructure::UpdateRSI() {
   // Store previous RSI value
   m_rsiPrev = m_rsi;
   
   // Get current RSI value
   m_rsi = CalculateRSI();
   
   // Update RSI features if Hurst is available
   if(m_hurstInfo.value > 0) {
      // Get dynamic RSI levels based on Hurst
      GetDynamicRSILevels(
         m_hurstInfo.value,
         GetMarketStructure(),
         m_dynamicRSIOverbought,
         m_dynamicRSIOversold
      );
      
      // Check for RSI divergence if enabled
      if(m_useRSIDivergence) {
         m_rsiBullDivergence = DetectRSIDivergence(true);
         m_rsiBearDivergence = DetectRSIDivergence(false);
      }
      
      // Get multi-timeframe RSI if enabled
      if(m_useMultiTimeframeRSI) {
         m_mtfRsi = GetMultiTimeframeRSI();
      }
      
      // Calculate RSI-Hurst alignment score
      m_rsiHurstAlignment = GetRSIHurstAlignment(m_rsi, m_hurstInfo.value);
   }
}

//+------------------------------------------------------------------+
//| Get dynamic RSI levels based on Hurst exponent                   |
//+------------------------------------------------------------------+
void CMarketStructure::GetDynamicRSILevels(
   double hurstValue, 
   ENUM_MARKET_STRUCTURE marketStructure, 
   double &overbought, 
   double &oversold
) {
   // Mặc định
   overbought = m_rsiOverbought;  
   oversold = m_rsiOversold;      
   
   // Điều chỉnh dựa trên Hurst
   if(hurstValue > 0.60) {  // Xu hướng mạnh
      // Thị trường xu hướng - mở rộng ngưỡng RSI
      overbought = 75;  // Cho phép RSI cao hơn trong uptrend
      oversold = 30;    // Ngưỡng thấp hơn cho downtrend
   }
   else if(hurstValue < 0.45) {  // Thị trường đảo chiều
      // Thị trường mean-reversion - thu hẹp ngưỡng RSI
      overbought = 60;  // Ngưỡng thấp hơn để phát hiện sớm đỉnh
      oversold = 40;    // Ngưỡng cao hơn để phát hiện sớm đáy
   }
   
   // Điều chỉnh thêm theo cấu trúc thị trường
   if(marketStructure == MARKET_STRONG_UPTREND) {
      overbought += 5;  // Thêm dung sai cho uptrend mạnh
   }
   else if(marketStructure == MARKET_STRONG_DOWNTREND) {
      oversold -= 5;    // Thêm dung sai cho downtrend mạnh
   }
}

//+------------------------------------------------------------------+
//| Detect RSI divergence                                             |
//+------------------------------------------------------------------+
bool CMarketStructure::DetectRSIDivergence(bool isBullish) {
   double rsiValues[];
   double closeValues[];
   
   ArraySetAsSeries(rsiValues, true);
   ArraySetAsSeries(closeValues, true);
   
   // Get RSI values
   if(CopyBuffer(m_rsiHandle, 0, 0, 30, rsiValues) < 30) {
      return false;
   }
   
   // Get price values
   if(CopyClose(m_symbol, m_timeframe, 0, 30, closeValues) < 30) {
      return false;
   }
   
   // Tìm các đỉnh/đáy
   int price_extreme1 = -1;
   int price_extreme2 = -1;
   int rsi_extreme1 = -1;
   int rsi_extreme2 = -1;
   
   if(isBullish) {  // Phân kỳ tăng (Bullish)
      // Tìm 2 đáy giá
      for(int i = 2; i < 28; i++) {
         if(closeValues[i] <= closeValues[i-1] && 
            closeValues[i] <= closeValues[i-2] && 
            closeValues[i] <= closeValues[i+1] && 
            closeValues[i] <= closeValues[i+2]) {
            if(price_extreme1 == -1) {
               price_extreme1 = i;
            } else if(price_extreme2 == -1 && i > price_extreme1 + 3) {
               price_extreme2 = i;
               break;
            }
         }
      }
      
      // Tìm 2 đáy RSI tương ứng
      if(price_extreme1 != -1 && price_extreme2 != -1) {
         // Tìm đáy RSI gần đáy giá 1
         for(int i = price_extreme1 - 2; i <= price_extreme1 + 2; i++) {
            if(i >= 2 && i < 28) {
               if(rsiValues[i] <= rsiValues[i-1] && rsiValues[i] <= rsiValues[i+1]) {
                  rsi_extreme1 = i;
                  break;
               }
            }
         }
         
         // Tìm đáy RSI gần đáy giá 2
         for(int i = price_extreme2 - 2; i <= price_extreme2 + 2; i++) {
            if(i >= 2 && i < 28) {
               if(rsiValues[i] <= rsiValues[i-1] && rsiValues[i] <= rsiValues[i+1]) {
                  rsi_extreme2 = i;
                  break;
               }
            }
         }
         
         // Xác nhận phân kỳ tăng: giá thấp hơn nhưng RSI cao hơn
         if(rsi_extreme1 != -1 && rsi_extreme2 != -1) {
            if(closeValues[price_extreme2] < closeValues[price_extreme1] && 
               rsiValues[rsi_extreme2] > rsiValues[rsi_extreme1]) {
               return true;  // Phân kỳ tăng xác nhận
            }
         }
      }
   }
   else {  // Phân kỳ giảm (Bearish)
      // Tìm 2 đỉnh giá
      for(int i = 2; i < 28; i++) {
         if(closeValues[i] >= closeValues[i-1] && 
            closeValues[i] >= closeValues[i-2] && 
            closeValues[i] >= closeValues[i+1] && 
            closeValues[i] >= closeValues[i+2]) {
            if(price_extreme1 == -1) {
               price_extreme1 = i;
            } else if(price_extreme2 == -1 && i > price_extreme1 + 3) {
               price_extreme2 = i;
               break;
            }
         }
      }
      
      // Tìm 2 đỉnh RSI tương ứng
      if(price_extreme1 != -1 && price_extreme2 != -1) {
         // Tìm đỉnh RSI gần đỉnh giá 1
         for(int i = price_extreme1 - 2; i <= price_extreme1 + 2; i++) {
            if(i >= 2 && i < 28) {
               if(rsiValues[i] >= rsiValues[i-1] && rsiValues[i] >= rsiValues[i+1]) {
                  rsi_extreme1 = i;
                  break;
               }
            }
         }
         
         // Tìm đỉnh RSI gần đỉnh giá 2
         for(int i = price_extreme2 - 2; i <= price_extreme2 + 2; i++) {
            if(i >= 2 && i < 28) {
               if(rsiValues[i] >= rsiValues[i-1] && rsiValues[i] >= rsiValues[i+1]) {
                  rsi_extreme2 = i;
                  break;
               }
            }
         }
         
         // Xác nhận phân kỳ giảm: giá cao hơn nhưng RSI thấp hơn
         if(rsi_extreme1 != -1 && rsi_extreme2 != -1) {
            if(closeValues[price_extreme2] > closeValues[price_extreme1] && 
               rsiValues[rsi_extreme2] < rsiValues[rsi_extreme1]) {
               return true;  // Phân kỳ giảm xác nhận
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get multi-timeframe RSI                                           |
//+------------------------------------------------------------------+
MultiTimeframeRSI CMarketStructure::GetMultiTimeframeRSI() {
   MultiTimeframeRSI result;
   result.current = 50;
   result.higher = 50;
   result.lower = 50;
   result.aligned = false;
   
   // Xác định khung thời gian
   ENUM_TIMEFRAMES higherTF = GetHigherTimeframe(m_timeframe);
   ENUM_TIMEFRAMES lowerTF = GetLowerTimeframe(m_timeframe);
   
   // Tính RSI cho mỗi khung
   int rsiHandleCurrent = m_rsiHandle;
   int rsiHandleHigher = iRSI(m_symbol, higherTF, m_rsiPeriod, PRICE_CLOSE);
   int rsiHandleLower = iRSI(m_symbol, lowerTF, m_rsiPeriod, PRICE_CLOSE);
   
   double bufferCurrent[], bufferHigher[], bufferLower[];
   
   if(CopyBuffer(rsiHandleCurrent, 0, 0, 1, bufferCurrent) == 1 &&
      CopyBuffer(rsiHandleHigher, 0, 0, 1, bufferHigher) == 1 &&
      CopyBuffer(rsiHandleLower, 0, 0, 1, bufferLower) == 1) {
      
      result.current = bufferCurrent[0];
      result.higher = bufferHigher[0];
      result.lower = bufferLower[0];
      
      // RSI cùng hướng khi tất cả > 50 hoặc < 50
      bool allBullish = (result.current > 50 && result.higher > 50 && result.lower > 50);
      bool allBearish = (result.current < 50 && result.higher < 50 && result.lower < 50);
      result.aligned = (allBullish || allBearish);
   }
   
   // Release handles
   if(rsiHandleHigher != INVALID_HANDLE) IndicatorRelease(rsiHandleHigher);
   if(rsiHandleLower != INVALID_HANDLE) IndicatorRelease(rsiHandleLower);
   
   return result;
}

//+------------------------------------------------------------------+
//| Get RSI-Hurst alignment score                                     |
//+------------------------------------------------------------------+
double CMarketStructure::GetRSIHurstAlignment(double rsiValue, double hurstValue) {
   // Tính mức độ khớp (0-100%)
   double alignment = 0;
   
   // 1. Kiểm tra xu hướng Hurst
   bool hurstBullish = (hurstValue > 0.53);
   bool hurstBearish = (hurstValue < 0.47);
   
   // 2. Kiểm tra xu hướng RSI
   bool rsiBullish = (rsiValue > 55);
   bool rsiBearish = (rsiValue < 45);
   
   // 3. Đánh giá mức khớp
   if((hurstBullish && rsiBullish) || (hurstBearish && rsiBearish)) {
      // RSI và Hurst cùng xác nhận một hướng
      alignment = 100;
   }
   else if((hurstBullish && !rsiBearish) || (hurstBearish && !rsiBullish)) {
      // Một xác nhận, một không phản đối
      alignment = 75;
   }
   else if((!hurstBullish && !hurstBearish) || (rsiValue >= 45 && rsiValue <= 55)) {
      // Một hoặc cả hai ở trạng thái trung tính
      alignment = 50;
   }
   else {
      // Mâu thuẫn - một tăng, một giảm
      alignment = 25;
   }
   
   return alignment;
}

//+------------------------------------------------------------------+
//| Validate RSI signal based on Hurst mode                          |
//+------------------------------------------------------------------+
bool CMarketStructure::IsValidRSISignal(bool isBuy) {
   double rsiValue = m_rsi;
   double rsiPrevValue = m_rsiPrev;
   double hurstValue = m_hurstInfo.value;
   
   // Nếu thị trường đang có xu hướng mạnh (Hurst > 0.6)
   if(hurstValue > 0.6) {
      if(isBuy) {
         // Trong uptrend mạnh, chỉ lấy tín hiệu mua khi RSI >= 50
         return rsiValue >= 50;
      } else {
         // Trong uptrend mạnh, chỉ lấy tín hiệu bán khi RSI >= 70 (quá mua)
         return rsiValue >= 70;
      }
   }
   // Nếu thị trường đang mean-reverting (Hurst < 0.4)
   else if(hurstValue < 0.4) {
      if(isBuy) {
         // Trong mean-reverting, lấy tín hiệu mua khi RSI <= 40 (quá bán)
         return rsiValue <= 40;
      } else {
         // Trong mean-reverting, lấy tín hiệu bán khi RSI >= 60
         return rsiValue >= 60;
      }
   }
   // Thị trường trung tính (0.4 <= Hurst <= 0.6)
   else {
      if(isBuy) {
         // Lấy tín hiệu mua khi RSI vượt lên trên 50 từ dưới
         return rsiValue > 50 && rsiPrevValue <= 50;
      } else {
         // Lấy tín hiệu bán khi RSI giảm xuống dưới 50 từ trên
         return rsiValue < 50 && rsiPrevValue >= 50;
      }
   }
}

//+------------------------------------------------------------------+
//| Update all technical indicators                                  |
//+------------------------------------------------------------------+
void CMarketStructure::UpdateIndicators() {
   // 1. Calculate standard indicators
   m_atr = iATR(m_symbol, m_timeframe, m_atrPeriod, 0);
   m_adx = iADX(m_symbol, m_timeframe, m_adxPeriod, PRICE_CLOSE, MODE_MAIN, 0);
   m_rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, 0);
   m_stochK = iStochastic(m_symbol, m_timeframe, m_stochKPeriod, m_stochDPeriod, m_stochSlowing, MODE_SMA, 0, MODE_MAIN, 0);
   m_stochD = iStochastic(m_symbol, m_timeframe, m_stochKPeriod, m_stochDPeriod, m_stochSlowing, MODE_SMA, 0, MODE_SIGNAL, 0);
   m_emaFast = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   m_emaMedium = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   m_emaLong = iMA(m_symbol, m_timeframe, m_emaLongPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   m_bollUpper = iBands(m_symbol, m_timeframe, m_bollPeriod, m_bollDeviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   m_bollMiddle = iBands(m_symbol, m_timeframe, m_bollPeriod, m_bollDeviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
   m_bollLower = iBands(m_symbol, m_timeframe, m_bollPeriod, m_bollDeviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   
   // 2. Update volatility metrics
   m_previousVolatility = m_volatility;
   m_volatility = CalculateVolatility();
   m_isHighVolatility = m_volatility > m_volatilityThreshold;
   m_isVolatilityIncreasing = m_volatility > m_previousVolatility;
   
   // 3. Update RSI analysis if integrated
   UpdateRSI();
   
   // 4. Update Hurst Analysis if integrated
   if(m_hurstAnalysis != NULL) {
      // Cập nhật thông tin Hurst cơ bản
      m_hurstInfo = m_hurstAnalysis.CalculateForSymbol(m_symbol, m_timeframe, m_hurstPeriod);
      
      // Cập nhật đa tầng Hurst và phân tích phân kỳ
      UpdateHurstAnalysis();
   }
   
   // 5. Identify key trendlines and patterns
   IdentifyKeyTrendlines();
   m_triangleType = DetectTrianglePattern();
   m_hasValidChannel = DetectPriceChannel();
   
   // 6. Update pattern recognition
   UpdatePatternRecognition();
}

//+------------------------------------------------------------------+
//| Calculate Fibonacci ratio between two price moves                 |
//+------------------------------------------------------------------+
double CMarketStructure::CalculateFibonacciRatio(double move1, double move2) {
   if(move2 == 0) return 0;
   return MathAbs(move1 / move2);
}

//+------------------------------------------------------------------+
//| Check if harmonics pattern is valid                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsValidHarmonicPattern(double xabRatio, double abcRatio, double bcdRatio, double xadRatio) {
   // Placeholder for harmonic pattern validation logic
   return false;
}

//+------------------------------------------------------------------+
//| Detect harmonic pattern                                          |
//+------------------------------------------------------------------+
ENUM_HARMONIC_PATTERN CMarketStructure::DetectHarmonicPattern(int lookback) {
   // This is a simplified placeholder implementation
   // Real implementation would identify swing points, calculate ratios between legs,
   // and check for specific Fibonacci relationships
   
   return HARMONIC_NONE;
}

//+------------------------------------------------------------------+
//| Analyze market structure and return the current type             |
//+------------------------------------------------------------------+
ENUM_MARKET_STRUCTURE CMarketStructure::AnalyzeMarketStructure() {
   // Update all indicators first
   UpdateIndicators();
   
   // Detect current market structure
   if(IsVolatile())
      return MARKET_VOLATILE;
   
   if(IsChoppy())
      return MARKET_CHOPPY;
   
   // Check for trending market conditions
   if(IsTrending()) {
      // Determine trend direction and strength
      if(m_emaFast > m_emaMedium && m_emaMedium > m_emaLong) {
         // Uptrend
         if(m_adx > m_adxThreshold + 10)
            return MARKET_STRONG_UPTREND;
         else
            return MARKET_WEAK_UPTREND;
      }
      else if(m_emaFast < m_emaMedium && m_emaMedium < m_emaLong) {
         // Downtrend
         if(m_adx > m_adxThreshold + 10)
            return MARKET_STRONG_DOWNTREND;
         else
            return MARKET_WEAK_DOWNTREND;
      }
   }
   
   // Check for ranging market
   if(IsRanging())
      return MARKET_RANGING;
   
   // If no specific condition detected
   return MARKET_UNKNOWN;
}

//+------------------------------------------------------------------+
//| Get market structure with Hurst integration                      |
//+------------------------------------------------------------------+
ENUM_MARKET_STRUCTURE CMarketStructure::GetMarketStructure() {
   // Get basic market structure from technical indicators
   ENUM_MARKET_STRUCTURE structureFromIndicators = AnalyzeMarketStructure();
   
   // If Hurst Analysis is available, integrate it
   if(m_hurstAnalysis != NULL) {
      ENUM_MARKET_STRUCTURE structureFromHurst = m_hurstAnalysis.GetMarketRegime(m_hurstInfo.value);
      
      // Adjust struct based on Hurst exponent if reliability is good
      if(m_hurstInfo.reliability >= 70) {
         if(m_hurstInfo.value > 0.60 && (structureFromIndicators == MARKET_WEAK_UPTREND || 
                                       structureFromIndicators == MARKET_STRONG_UPTREND)) {
            return MARKET_STRONG_UPTREND;
         }
         else if(m_hurstInfo.value < 0.40 && (structureFromIndicators == MARKET_WEAK_DOWNTREND || 
                                            structureFromIndicators == MARKET_STRONG_DOWNTREND)) {
            return MARKET_STRONG_DOWNTREND;
         }
         else if(m_hurstInfo.value > 0.45 && m_hurstInfo.value < 0.55 && 
                (structureFromIndicators == MARKET_CHOPPY || structureFromIndicators == MARKET_RANGING)) {
            return MARKET_RANGING;
         }
      }
   }
   
   // Return the indicator-based market structure if Hurst not available or not reliable
   return structureFromIndicators;
}

//+------------------------------------------------------------------+
//| Check if market is trending                                       |
//+------------------------------------------------------------------+
bool CMarketStructure::IsTrending() {
   return m_adx > m_adxThreshold && 
          MathAbs(m_emaFast - m_emaLong) > m_atr * 2;
}

//+------------------------------------------------------------------+
//| Check if market is ranging                                        |
//+------------------------------------------------------------------+
bool CMarketStructure::IsRanging() {
   // Ranging markets typically have low ADX
   if(m_adx > m_adxThreshold)
      return false;
   
   // Check if price is oscillating between bollinger bands
   double close = iClose(m_symbol, m_timeframe, 0);
   double bollWidth = (m_bollUpper - m_bollLower) / m_bollMiddle;
   
   return bollWidth < 0.05 || // Narrow bands
          (MathAbs(m_emaFast - m_emaMedium) < m_atr * 0.5 && 
           MathAbs(m_emaMedium - m_emaLong) < m_atr * 1.0);
}

//+------------------------------------------------------------------+
//| Check if market is volatile                                       |
//+------------------------------------------------------------------+
bool CMarketStructure::IsVolatile() {
   return m_volatility > m_volatilityThreshold * 1.5 || // Extremely high volatility
          m_atr > m_maxATRForNormalTrading;
}

//+------------------------------------------------------------------+
//| Check if market is choppy                                         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsChoppy() {
   // Choppy markets have low ADX and frequent crosses of fast/medium EMAs
   if(m_adx > m_adxThreshold)
      return false;
   
   // Check EMA crosses in recent bars
   int crossCount = 0;
   double prevFast, prevMedium;
   
   for(int i = 1; i < 10; i++) {
      prevFast = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
      prevMedium = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
      
      double nextFast = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, i-1);
      double nextMedium = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, i-1);
      
      if((prevFast > prevMedium && nextFast < nextMedium) || 
         (prevFast < prevMedium && nextFast > nextMedium)) {
         crossCount++;
      }
   }
   
   return crossCount >= 2; // At least 2 crosses in 10 bars = choppy
}

//+------------------------------------------------------------------+
//| Check if market is overbought                                     |
//+------------------------------------------------------------------+
bool CMarketStructure::IsOverbought() {
   return (m_rsi > m_rsiOverbought) && 
          iClose(m_symbol, m_timeframe, 0) > m_bollUpper;
}

//+------------------------------------------------------------------+
//| Check if market is oversold                                       |
//+------------------------------------------------------------------+
bool CMarketStructure::IsOversold() {
   return (m_rsi < m_rsiOversold) && 
          iClose(m_symbol, m_timeframe, 0) < m_bollLower;
}

//+------------------------------------------------------------------+
//| Get trend strength on scale 0-100                                |
//+------------------------------------------------------------------+
int CMarketStructure::GetTrendStrength() {
   // Base trend strength on ADX
   int adxStrength = (int)MathMin(100, m_adx * 2);
   
   // Modify based on EMA alignment
   double emaAlignment = 0;
   if(m_emaFast > m_emaMedium && m_emaMedium > m_emaLong) {
      // Uptrend alignment
      emaAlignment = 30;
   }
   else if(m_emaFast < m_emaMedium && m_emaMedium < m_emaLong) {
      // Downtrend alignment
      emaAlignment = 30;
   }
   
   // Incorporate Hurst value if available
   double hurstModifier = 0;
   if(m_hurstAnalysis != NULL) {
      if(m_hurstInfo.value > 0.5) {
         hurstModifier = (m_hurstInfo.value - 0.5) * 100;
      }
      else {
         hurstModifier = (0.5 - m_hurstInfo.value) * 100;
      }
   }
   
   // Combine all factors
   return (int)MathMin(100, adxStrength * 0.5 + emaAlignment + hurstModifier * 0.2);
}

//+------------------------------------------------------------------+
//| Check for bullish divergence                                      |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBullishDivergence(int lookbackBars) {
   double lowestLow = DBL_MAX;
   double lowestRSI = DBL_MAX;
   int lowestLowBar = -1;
   int lowestRSIBar = -1;
   
   // Find lowest low and corresponding RSI in lookback period
   for(int i = 0; i < lookbackBars; i++) {
      double low = iLow(m_symbol, m_timeframe, i);
      double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
      
      if(low < lowestLow) {
         lowestLow = low;
         lowestLowBar = i;
      }
      
      if(rsi < lowestRSI) {
         lowestRSI = rsi;
         lowestRSIBar = i;
      }
   }
   
   // Look for a second low that's lower than the first but with higher RSI
   if(lowestLowBar > 0 && lowestRSIBar > 0) {
      for(int i = 0; i < lookbackBars; i++) {
         if(i != lowestLowBar) {
            double low = iLow(m_symbol, m_timeframe, i);
            double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
            
            // Check for lower low with higher RSI
            if(low < lowestLow && rsi > lowestRSI) {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for bearish divergence                                      |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBearishDivergence(int lookbackBars) {
   double highestHigh = -DBL_MAX;
   double highestRSI = -DBL_MAX;
   int highestHighBar = -1;
   int highestRSIBar = -1;
   
   // Find highest high and corresponding RSI in lookback period
   for(int i = 0; i < lookbackBars; i++) {
      double high = iHigh(m_symbol, m_timeframe, i);
      double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
      
      if(high > highestHigh) {
         highestHigh = high;
         highestHighBar = i;
      }
      
      if(rsi > highestRSI) {
         highestRSI = rsi;
         highestRSIBar = i;
      }
   }
   
   // Look for a second high that's higher than the first but with lower RSI
   if(highestHighBar > 0 && highestRSIBar > 0) {
      for(int i = 0; i < lookbackBars; i++) {
         if(i != highestHighBar) {
            double high = iHigh(m_symbol, m_timeframe, i);
            double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
            
            // Check for higher high with lower RSI
            if(high > highestHigh && rsi < highestRSI) {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for potential price reversal                               |
//+------------------------------------------------------------------+
bool CMarketStructure::IsPotentialReversal() {
   ENUM_MARKET_STRUCTURE currentStructure = GetMarketStructure();
   
   // Check if market is in trend
   if(currentStructure == MARKET_STRONG_UPTREND || currentStructure == MARKET_WEAK_UPTREND) {
      // Check for bearish divergence or overbought in uptrend
      return IsBearishDivergence(20) || IsOverbought();
   }
   else if(currentStructure == MARKET_STRONG_DOWNTREND || currentStructure == MARKET_WEAK_DOWNTREND) {
      // Check for bullish divergence or oversold in downtrend
      return IsBullishDivergence(20) || IsOversold();
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for breakout                                               |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBreakout() {
   double close = iClose(m_symbol, m_timeframe, 0);
   double prev_close = iClose(m_symbol, m_timeframe, 1);
   
   // Check for price breaking above/below Bollinger Bands with volume
   if((close > m_bollUpper && prev_close <= m_bollUpper) || 
      (close < m_bollLower && prev_close >= m_bollLower)) {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get current market bias                                          |
//+------------------------------------------------------------------+
int CMarketStructure::GetBias() {
   ENUM_MARKET_STRUCTURE currentStructure = GetMarketStructure();
   
   // Determine bias based on market structure
   switch(currentStructure) {
      case MARKET_STRONG_UPTREND:
      case MARKET_WEAK_UPTREND:
         return 1;   // Bullish
         
      case MARKET_STRONG_DOWNTREND:
      case MARKET_WEAK_DOWNTREND:
         return -1;  // Bearish
         
      case MARKET_RANGING:
         // In ranging market, check if we're near support/resistance
         if(iClose(m_symbol, m_timeframe, 0) > m_bollMiddle)
            return 1;   // Upper half of range
         else
            return -1;  // Lower half of range
         
      case MARKET_VOLATILE:
      case MARKET_CHOPPY:
      case MARKET_UNKNOWN:
      default:
         return 0;   // Neutral
   }
}

//+------------------------------------------------------------------+
//| Get volatility level compared to historical                      |
//+------------------------------------------------------------------+
double CMarketStructure::GetVolatilityLevel() {
   return m_volatility;
}

//+------------------------------------------------------------------+
//| Update settings                                                  |
//+------------------------------------------------------------------+
void CMarketStructure::UpdateSettings(
   int rsiPeriod,
   int adxPeriod,
   double adxThreshold,
   int emaFastPeriod,
   int emaMediumPeriod,
   int emaLongPeriod
) {
   m_rsiPeriod = rsiPeriod;
   m_adxPeriod = adxPeriod;
   m_adxThreshold = adxThreshold;
   m_emaFastPeriod = emaFastPeriod;
   m_emaMediumPeriod = emaMediumPeriod;
   m_emaLongPeriod = emaLongPeriod;
   
   // Update indicators with new settings
   UpdateIndicators();
}

//+------------------------------------------------------------------+
//| Xác định các đỉnh và đáy quan trọng                              |
//+------------------------------------------------------------------+
void CMarketStructure::IdentifySwingHighsLows(int &highPoints[], int &lowPoints[], int &highCount, int &lowCount, int maxBars) {
   highCount = 0;
   lowCount = 0;
   
   // Xác định các đỉnh
   for(int i = 2; i < maxBars - 2; i++) {
      // Kiểm tra đỉnh
      if(iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i-1) &&
         iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i-2) &&
         iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i+1) &&
         iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i+2)) {
         
         // Thêm vào mảng đỉnh
         if(highCount < ArraySize(highPoints)) {
            highPoints[highCount] = i;
            highCount++;
         }
      }
      
      // Kiểm tra đáy
      if(iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i-1) &&
         iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i-2) &&
         iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i+1) &&
         iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i+2)) {
         
         // Thêm vào mảng đáy
         if(lowCount < ArraySize(lowPoints)) {
            lowPoints[lowCount] = i;
            lowCount++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Tính giá tại thời điểm trên trendline                           |
//+------------------------------------------------------------------+
double CMarketStructure::CalculateTrendlinePrice(const TrendlineInfo &tl, datetime time) {
   if(!tl.isValid) return 0;
   
   // Tính slope và intercept
   double timeRange = (double)(tl.time2 - tl.time1);
   if(timeRange == 0) return 0; // Tránh chia cho 0
   
   double slope = (tl.price2 - tl.price1) / timeRange;
   double intercept = tl.price1 - slope * (double)(tl.time1);
   
   // Tính giá tại thời điểm
   return slope * (double)(time) + intercept;
}

//+------------------------------------------------------------------+
//| Xác định trendline trên và dưới quan trọng nhất                  |
//+------------------------------------------------------------------+
void CMarketStructure::IdentifyKeyTrendlines() {
   // Reset thông tin
   m_upperTrendline.isValid = false;
   m_lowerTrendline.isValid = false;
   
   // Xác định các đỉnh và đáy tiềm năng
   int highPoints[10], lowPoints[10];
   int highCount = 0, lowCount = 0;
   
   // Tìm các đỉnh và đáy quan trọng trong 200 nến
   ArrayResize(highPoints, 10);
   ArrayResize(lowPoints, 10);
   IdentifySwingHighsLows(highPoints, lowPoints, highCount, lowCount, 200);
   
   // Tìm trendline trên (kết nối các đỉnh)
   if(highCount >= 2) {
      // Thử kết nối các đỉnh khác nhau để tìm trendline mạnh nhất
      double bestStrength = 0;
      for(int i = 0; i < highCount - 1; i++) {
         for(int j = i + 1; j < highCount; j++) {
            TrendlineInfo tempTL;
            tempTL.time1 = iTime(m_symbol, m_timeframe, highPoints[i]);
            tempTL.time2 = iTime(m_symbol, m_timeframe, highPoints[j]);
            tempTL.price1 = iHigh(m_symbol, m_timeframe, highPoints[i]);
            tempTL.price2 = iHigh(m_symbol, m_timeframe, highPoints[j]);
            tempTL.isValid = true;
            
            // Đếm số điểm chạm và kiểm tra đường thẳng có hợp lệ
            double strength = ValidateTrendline(tempTL, true);
            
            if(strength > bestStrength) {
               bestStrength = strength;
               m_upperTrendline = tempTL;
               m_upperTrendline.isValid = true;
               m_upperTrendline.strength = strength;
            }
         }
      }
   }
   
   // Tìm trendline dưới (kết nối các đáy)
   if(lowCount >= 2) {
      double bestStrength = 0;
      for(int i = 0; i < lowCount - 1; i++) {
         for(int j = i + 1; j < lowCount; j++) {
            TrendlineInfo tempTL;
            tempTL.time1 = iTime(m_symbol, m_timeframe, lowPoints[i]);
            tempTL.time2 = iTime(m_symbol, m_timeframe, lowPoints[j]);
            tempTL.price1 = iLow(m_symbol, m_timeframe, lowPoints[i]);
            tempTL.price2 = iLow(m_symbol, m_timeframe, lowPoints[j]);
            tempTL.isValid = true;
            
            // Đếm số điểm chạm và kiểm tra đường thẳng có hợp lệ
            double strength = ValidateTrendline(tempTL, false);
            
            if(strength > bestStrength) {
               bestStrength = strength;
               m_lowerTrendline = tempTL;
               m_lowerTrendline.isValid = true;
               m_lowerTrendline.strength = strength;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra trendline có bao nhiêu điểm chạm và tính độ mạnh        |
//+------------------------------------------------------------------+
double CMarketStructure::ValidateTrendline(TrendlineInfo &tl, bool isUpper, int maxBars) {
   if(!tl.isValid) return 0;
   
   int touchCount = 0;
   double tolerance = m_atr * 0.5; // Dung sai bằng nửa ATR
   datetime lastTouchTime = 0;
   
   // Kiểm tra từng thanh nến xem có chạm trendline không
   for(int i = 0; i < maxBars; i++) {
      datetime barTime = iTime(m_symbol, m_timeframe, i);
      double linePrice = CalculateTrendlinePrice(tl, barTime);
      
      if(isUpper) {
         if(MathAbs(iHigh(m_symbol, m_timeframe, i) - linePrice) <= tolerance) {
            touchCount++;
            lastTouchTime = barTime;
         }
      } else {
         if(MathAbs(iLow(m_symbol, m_timeframe, i) - linePrice) <= tolerance) {
            touchCount++;
            lastTouchTime = barTime;
         }
      }
   }
   
   tl.touchPoints = touchCount;
   tl.lastTouch = lastTouchTime;
   
   // Tính độ mạnh dựa trên số điểm chạm và khoảng thời gian
   double timeStrength = (tl.time1 - tl.time2) / (60.0 * 60.0 * 24.0); // Số ngày
   if(timeStrength < 0) timeStrength = -timeStrength;
   
   return touchCount * 0.8 + timeStrength * 0.2; // Tính điểm độ mạnh
}

//+------------------------------------------------------------------+
//| Phát hiện kênh giá                                               |
//+------------------------------------------------------------------+
bool CMarketStructure::DetectPriceChannel() {
   // Kiểm tra hai trendline có tồn tại và hợp lệ
   if(!m_upperTrendline.isValid || !m_lowerTrendline.isValid) {
      return false;
   }
   
   // Kiểm tra hai trendline có song song không
   double slope1 = (m_upperTrendline.price2 - m_upperTrendline.price1) / 
                  (double)(m_upperTrendline.time2 - m_upperTrendline.time1);
   
   double slope2 = (m_lowerTrendline.price2 - m_lowerTrendline.price1) / 
                  (double)(m_lowerTrendline.time2 - m_lowerTrendline.time1);
   
   // Nếu độ dốc tương đối gần nhau (song song)
   if(MathAbs(slope1 - slope2) < 0.0001) {
      datetime currentTime = TimeCurrent();
      m_upperChannel = CalculateTrendlinePrice(m_upperTrendline, currentTime);
      m_lowerChannel = CalculateTrendlinePrice(m_lowerTrendline, currentTime);
      m_channelWidth = m_upperChannel - m_lowerChannel;
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Phát hiện mô hình tam giác                                       |
//+------------------------------------------------------------------+
ENUM_TRIANGLE_TYPE CMarketStructure::DetectTrianglePattern() {
   if(!m_upperTrendline.isValid || !m_lowerTrendline.isValid) 
      return TRIANGLE_NONE;
   
   // Tính độ dốc hai đường
   double upperSlope = (m_upperTrendline.price2 - m_upperTrendline.price1) / 
                      (double)(m_upperTrendline.time2 - m_upperTrendline.time1);
   
   double lowerSlope = (m_lowerTrendline.price2 - m_lowerTrendline.price1) / 
                      (double)(m_lowerTrendline.time2 - m_lowerTrendline.time1);
   
   // Tam giác đối xứng (cả hai đường hướng vào nhau)
   if(upperSlope < -0.0001 && lowerSlope > 0.0001) {
      return TRIANGLE_SYMMETRICAL;
   }
   
   // Tam giác tăng (đường dưới đi lên, đường trên ngang)
   if(MathAbs(upperSlope) < 0.0001 && lowerSlope > 0.0001) {
      return TRIANGLE_ASCENDING;
   }
   
   // Tam giác giảm (đường trên đi xuống, đường dưới ngang)
   if(upperSlope < -0.0001 && MathAbs(lowerSlope) < 0.0001) {
      return TRIANGLE_DESCENDING;
   }
   
   return TRIANGLE_NONE;
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu giá gần trendline hỗ trợ                            |
//+------------------------------------------------------------------+
bool CMarketStructure::IsSupportTrendlineNearby(int pipsThreshold) {
   if(!m_lowerTrendline.isValid) return false;
   
   double currentPrice = iClose(m_symbol, m_timeframe, 0);
   datetime currentTime = TimeCurrent();
   double supportPrice = CalculateTrendlinePrice(m_lowerTrendline, currentTime);
   
   double distance = MathAbs(currentPrice - supportPrice);
   double thresholdInPrice = PipsToPrice(m_symbol, (double)pipsThreshold);
   
   return (distance <= thresholdInPrice);
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu giá gần trendline kháng cự                          |
//+------------------------------------------------------------------+
bool CMarketStructure::IsResistanceTrendlineNearby(int pipsThreshold) {
   if(!m_upperTrendline.isValid) return false;
   
   double currentPrice = iClose(m_symbol, m_timeframe, 0);
   datetime currentTime = TimeCurrent();
   double resistancePrice = CalculateTrendlinePrice(m_upperTrendline, currentTime);
   
   double distance = MathAbs(currentPrice - resistancePrice);
   double thresholdInPrice = PipsToPrice(m_symbol, (double)pipsThreshold);
   
   return (distance <= thresholdInPrice);
}

//+------------------------------------------------------------------+
//| Kiểm tra đột phá mô hình giá                                     |
//+------------------------------------------------------------------+
bool CMarketStructure::CheckPatternBreakout(bool &isBullish) {
   // 1. Kiểm tra đột phá kênh giá
   if(m_hasValidChannel) {
      double currentPrice = iClose(m_symbol, m_timeframe, 0);
      
      // Xác nhận đột phá kênh (cần xác nhận rõ ràng)
      if(currentPrice > m_upperChannel + (m_channelWidth * 0.03)) {
         isBullish = true;
         return true;
      }
      else if(currentPrice < m_lowerChannel - (m_channelWidth * 0.03)) {
         isBullish = false;
         return true;
      }
   }
   
   // 2. Kiểm tra đột phá mô hình tam giác
   if(m_triangleType != TRIANGLE_NONE) {
      // Tính điểm hội tụ của tam giác
      double convergencePrice = 0;
      datetime convergenceTime = 0;
      
      // TODO: Tính toán điểm hội tụ và kiểm tra đột phá
   }
   
   // 3. Kiểm tra giá chạm trendline quan trọng
   double currentPrice = iClose(m_symbol, m_timeframe, 0);
   datetime currentTime = TimeCurrent();
   
   if(m_upperTrendline.isValid) {
      double upperPrice = CalculateTrendlinePrice(m_upperTrendline, currentTime);
      // Kiểm tra nếu giá đang test trendline trên
      if(MathAbs(currentPrice - upperPrice) < m_atr * 0.3) {
         // Xác nhận với Hurst để tìm cơ hội Short
         if(m_hurstInfo.value < 0.45) {
            isBullish = false;
            return true;
         }
      }
   }
   
   if(m_lowerTrendline.isValid) {
      double lowerPrice = CalculateTrendlinePrice(m_lowerTrendline, currentTime);
      // Kiểm tra nếu giá đang test trendline dưới
      if(MathAbs(currentPrice - lowerPrice) < m_atr * 0.3) {
         // Xác nhận với Hurst để tìm cơ hội Long
         if(m_hurstInfo.value > 0.55) {
            isBullish = true;
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Initialize Hurst Analysis component                              |
//+------------------------------------------------------------------+
void CMarketStructure::InitializeHurstAnalysis(
   int hurstPeriod,
   double hurstTrendThreshold,
   double hurstMeanRevThreshold
) {
   // Create Hurst Analysis object if not exists
   if(m_hurstAnalysis == NULL) {
      m_hurstAnalysis = new CHurstAnalysis(
         hurstPeriod,
         hurstTrendThreshold,
         hurstMeanRevThreshold
      );
   } else {
      // Update settings if already exists
      m_hurstAnalysis.SetParameters(
         hurstPeriod,
         hurstTrendThreshold,
         hurstMeanRevThreshold,
         true, // Adaptive thresholds
         70,   // Min reliability
         1.2   // Sensitivity
      );
   }
   
   // Calculate initial Hurst value
   m_hurstInfo = m_hurstAnalysis.CalculateForSymbol(m_symbol, m_timeframe, hurstPeriod);
}

//+------------------------------------------------------------------+
//| Update pattern recognition                                        |
//+------------------------------------------------------------------+
void CMarketStructure::UpdatePatternRecognition() {
   // Detect patterns
   m_lastPattern.candlePattern = DetectCandlePattern();
   m_lastPattern.harmonicPattern = DetectHarmonicPattern();
   m_lastPattern.wyckoffPhase = DetectWyckoffPhase();
   m_lastPattern.detectionTime = TimeCurrent();
   
   // Calculate overall pattern strength and direction
   int candleStrength = 0;
   int harmonicStrength = 0;
   int wyckoffStrength = 0;
   int candleDirection = 0;
   int harmonicDirection = 0;
   int wyckoffDirection = 0;
   
   // Analyze candle patterns
   switch(m_lastPattern.candlePattern) {
      case PATTERN_BULLISH_ENGULFING:
         candleStrength = 70;
         candleDirection = 1;
         m_lastPattern.patternDescription = "Bullish Engulfing";
         break;
      case PATTERN_BEARISH_ENGULFING:
         candleStrength = 70;
         candleDirection = -1;
         m_lastPattern.patternDescription = "Bearish Engulfing";
         break;
      case PATTERN_MORNING_STAR:
         candleStrength = 85;
         candleDirection = 1;
         m_lastPattern.patternDescription = "Morning Star";
         break;
      case PATTERN_EVENING_STAR:
         candleStrength = 85;
         candleDirection = -1;
         m_lastPattern.patternDescription = "Evening Star";
         break;
      case PATTERN_HAMMER:
         candleStrength = 60;
         candleDirection = 1;
         m_lastPattern.patternDescription = "Hammer";
         break;
      case PATTERN_SHOOTING_STAR:
         candleStrength = 60;
         candleDirection = -1;
         m_lastPattern.patternDescription = "Shooting Star";
         break;
      case PATTERN_PINBAR:
         double close = iClose(m_symbol, m_timeframe, 0);
         double open = iOpen(m_symbol, m_timeframe, 0);
         candleStrength = 75;
         candleDirection = (close > open) ? 1 : -1;
         m_lastPattern.patternDescription = "Pin Bar";
         break;
      default:
         candleStrength = 0;
         candleDirection = 0;
         break;
   }
   
   // Analyze Wyckoff phases
   switch(m_lastPattern.wyckoffPhase) {
      case WYCKOFF_ACCUMULATION:
         wyckoffStrength = 80;
         wyckoffDirection = 1; // Preparing for markup
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Accumulation";
         break;
      case WYCKOFF_DISTRIBUTION:
         wyckoffStrength = 80;
         wyckoffDirection = -1; // Preparing for markdown
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Distribution";
         break;
      case WYCKOFF_MARKUP:
         wyckoffStrength = 60;
         wyckoffDirection = 1;
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Markup";
         break;
      case WYCKOFF_MARKDOWN:
         wyckoffStrength = 60;
         wyckoffDirection = -1;
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Markdown";
         break;
      default:
         wyckoffStrength = 0;
         wyckoffDirection = 0;
         break;
   }
   
   // If no description, add a default one
   if(m_lastPattern.patternDescription == "")
      m_lastPattern.patternDescription = "No significant pattern";
   
   // Calculate weighted average of pattern strength and direction
   double totalStrength = candleStrength * 0.4 + harmonicStrength * 0.3 + wyckoffStrength * 0.3;
   
   // Only assign a direction if enough patterns agree
   if(candleDirection != 0 && wyckoffDirection != 0) {
      if(candleDirection == wyckoffDirection)
         m_lastPattern.patternDirection = candleDirection;
      else
         m_lastPattern.patternDirection = (candleStrength > wyckoffStrength) ? candleDirection : wyckoffDirection;
   }
   else if(candleDirection != 0)
      m_lastPattern.patternDirection = candleDirection;
   else if(wyckoffDirection != 0)
      m_lastPattern.patternDirection = wyckoffDirection;
   else
      m_lastPattern.patternDirection = 0;
   
   m_lastPattern.patternStrength = (int)MathRound(totalStrength);
}

//+------------------------------------------------------------------+
//| Detect candle patterns                                           |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CMarketStructure::DetectCandlePattern(int startBar, int lookback) {
   // Check for various candle patterns, starting with the strongest ones
   if(IsMorningStar(startBar))
      return PATTERN_MORNING_STAR;
      
   if(IsEveningStar(startBar))
      return PATTERN_EVENING_STAR;
      
   if(IsBullishEngulfing(startBar))
      return PATTERN_BULLISH_ENGULFING;
      
   if(IsBearishEngulfing(startBar))
      return PATTERN_BEARISH_ENGULFING;
      
   if(IsPinBar(startBar))
      return PATTERN_PINBAR;
      
   if(IsHammer(startBar))
      return PATTERN_HAMMER;
      
   if(IsShootingStar(startBar))
      return PATTERN_SHOOTING_STAR;
      
   if(IsDoji(startBar))
      return PATTERN_DOJI;
   
   return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Check for bullish engulfing pattern                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBullishEngulfing(int shift) {
   double currOpen = iOpen(m_symbol, m_timeframe, shift);
   double currClose = iClose(m_symbol, m_timeframe, shift);
   double prevOpen = iOpen(m_symbol, m_timeframe, shift + 1);
   double prevClose = iClose(m_symbol, m_timeframe, shift + 1);
   
   // Basic bullish engulfing pattern
   if(currClose > currOpen && // Current candle is bullish
      prevClose < prevOpen && // Previous candle is bearish
      currOpen < prevClose && // Current open is lower than previous close
      currClose > prevOpen)   // Current close is higher than previous open
   {
      // Check for additional confirmation
      double bodySize = MathAbs(currClose - currOpen);
      double prevBodySize = MathAbs(prevClose - prevOpen);
      
      // Current body should be larger than previous body
      if(bodySize > prevBodySize * (1.0 + 0.1 * m_candlePatternSensitivity))
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for bearish engulfing pattern                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBearishEngulfing(int shift) {
   double currOpen = iOpen(m_symbol, m_timeframe, shift);
   double currClose = iClose(m_symbol, m_timeframe, shift);
   double prevOpen = iOpen(m_symbol, m_timeframe, shift + 1);
   double prevClose = iClose(m_symbol, m_timeframe, shift + 1);
   
   // Basic bearish engulfing pattern
   if(currClose < currOpen && // Current candle is bearish
      prevClose > prevOpen && // Previous candle is bullish
      currOpen > prevClose && // Current open is higher than previous close
      currClose < prevOpen)   // Current close is lower than previous open
   {
      // Check for additional confirmation
      double bodySize = MathAbs(currClose - currOpen);
      double prevBodySize = MathAbs(prevClose - prevOpen);
      
      // Current body should be larger than previous body
      if(bodySize > prevBodySize * (1.0 + 0.1 * m_candlePatternSensitivity))
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for morning star pattern                                   |
//+------------------------------------------------------------------+
bool CMarketStructure::IsMorningStar(int shift) {
   if(shift + 2 >= Bars(m_symbol, m_timeframe)) return false;
   
   // First candle: bearish
   bool firstBearish = iClose(m_symbol, m_timeframe, shift + 2) < iOpen(m_symbol, m_timeframe, shift + 2);
   
   // Second candle: small body (doji or small candle)
   double secondBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 1) - iOpen(m_symbol, m_timeframe, shift + 1));
   bool secondSmall = secondBodySize < m_atr * 0.3;
   
   // Third candle: bullish
   bool thirdBullish = iClose(m_symbol, m_timeframe, shift) > iOpen(m_symbol, m_timeframe, shift);
   
   // Gap between first and second candle
   bool hasGap1 = iHigh(m_symbol, m_timeframe, shift + 1) < iLow(m_symbol, m_timeframe, shift + 2);
   
   // Gap between second and third candle
   bool hasGap2 = iLow(m_symbol, m_timeframe, shift) > iHigh(m_symbol, m_timeframe, shift + 1);
   
   // Third candle closes well into first candle body
   double firstBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 2) - iOpen(m_symbol, m_timeframe, shift + 2));
   double thirdBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift) - iOpen(m_symbol, m_timeframe, shift));
   bool thirdStrong = thirdBodySize > firstBodySize * 0.5;
   
   // Check overall pattern
   bool isPattern = firstBearish && secondSmall && thirdBullish && thirdStrong;
   
   // Adjust for sensitivity
   if(m_candlePatternSensitivity > 7) {
      // More relaxed rules for high sensitivity
      return isPattern;
   } else {
      // Stricter rules for lower sensitivity
      return isPattern && (hasGap1 || hasGap2);
   }
}

//+------------------------------------------------------------------+
//| Check for evening star pattern                                   |
//+------------------------------------------------------------------+
bool CMarketStructure::IsEveningStar(int shift) {
   if(shift + 2 >= Bars(m_symbol, m_timeframe)) return false;
   
   // First candle: bullish
   bool firstBullish = iClose(m_symbol, m_timeframe, shift + 2) > iOpen(m_symbol, m_timeframe, shift + 2);
   
   // Second candle: small body (doji or small candle)
   double secondBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 1) - iOpen(m_symbol, m_timeframe, shift + 1));
   bool secondSmall = secondBodySize < m_atr * 0.3;
   
   // Third candle: bearish
   bool thirdBearish = iClose(m_symbol, m_timeframe, shift) < iOpen(m_symbol, m_timeframe, shift);
   
   // Gap between first and second candle
   bool hasGap1 = iLow(m_symbol, m_timeframe, shift + 1) > iHigh(m_symbol, m_timeframe, shift + 2);
   
   // Gap between second and third candle
   bool hasGap2 = iHigh(m_symbol, m_timeframe, shift) < iLow(m_symbol, m_timeframe, shift + 1);
   
   // Third candle closes well into first candle body
   double firstBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 2) - iOpen(m_symbol, m_timeframe, shift + 2));
   double thirdBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift) - iOpen(m_symbol, m_timeframe, shift));
   bool thirdStrong = thirdBodySize > firstBodySize * 0.5;
   
   // Check overall pattern
   bool isPattern = firstBullish && secondSmall && thirdBearish && thirdStrong;
   
   // Adjust for sensitivity
   if(m_candlePatternSensitivity > 7) {
      // More relaxed rules for high sensitivity
      return isPattern;
   } else {
      // Stricter rules for lower sensitivity
      return isPattern && (hasGap1 || hasGap2);
   }
}

//+------------------------------------------------------------------+
//| Check for hammer pattern                                         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsHammer(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   double lowerShadow, upperShadow;
   
   // Calculate shadows based on whether candle is bullish or bearish
   if(close >= open) { // Bullish candle
      upperShadow = high - close;
      lowerShadow = open - low;
   } else { // Bearish candle
      upperShadow = high - open;
      lowerShadow = close - low;
   }
   
   // Check if it's a hammer
   bool isHammer = (lowerShadow > bodySize * 2) && // Lower shadow is at least twice the body size
                  (upperShadow < bodySize * 0.1) && // Very small or no upper shadow
                  (bodySize / totalSize < 0.3); // Body is relatively small compared to total candle size
   
   // Need prior downtrend for valid hammer
   bool priorDowntrend = true;
   double sum = 0;
   for(int i = shift + 1; i <= shift + 5; i++) {
      if(i < Bars(m_symbol, m_timeframe))
         sum += iClose(m_symbol, m_timeframe, i);
   }
   double avgClose = sum / 5;
   priorDowntrend = (avgClose > close);
   
   return isHammer && priorDowntrend;
}

//+------------------------------------------------------------------+
//| Check for shooting star pattern                                  |
//+------------------------------------------------------------------+
bool CMarketStructure::IsShootingStar(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   double lowerShadow, upperShadow;
   
   // Calculate shadows based on whether candle is bullish or bearish
   if(close >= open) { // Bullish candle
      upperShadow = high - close;
      lowerShadow = open - low;
   } else { // Bearish candle
      upperShadow = high - open;
      lowerShadow = close - low;
   }
   
   // Check if it's a shooting star
   bool isShootingStar = (upperShadow > bodySize * 2) && // Upper shadow is at least twice the body size
                        (lowerShadow < bodySize * 0.1) && // Very small or no lower shadow
                        (bodySize / totalSize < 0.3); // Body is relatively small compared to total candle size
   
   // Need prior uptrend for valid shooting star
   bool priorUptrend = true;
   double sum = 0;
   for(int i = shift + 1; i <= shift + 5; i++) {
      if(i < Bars(m_symbol, m_timeframe))
         sum += iClose(m_symbol, m_timeframe, i);
   }
   double avgClose = sum / 5;
   priorUptrend = (avgClose < close);
   
   return isShootingStar && priorUptrend;
}

//+------------------------------------------------------------------+
//| Check for doji pattern                                           |
//+------------------------------------------------------------------+
bool CMarketStructure::IsDoji(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   // Body should be very small compared to total candle size
   return (bodySize / totalSize < 0.1 * (11 - m_candlePatternSensitivity) / 10.0);
}

//+------------------------------------------------------------------+
//| Check for pin bar pattern                                        |
//+------------------------------------------------------------------+
bool CMarketStructure::IsPinBar(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   double bodyCenterPrice = (open + close) / 2.0;
   double upperPart = high - bodyCenterPrice;
   double lowerPart = bodyCenterPrice - low;
   
   bool isPinBar = false;
   
   // Bullish pin bar (tail pointing down)
   if(lowerPart / totalSize > 0.6 && bodySize / totalSize < 0.3) {
      isPinBar = true;
   }
   
   // Bearish pin bar (tail pointing up)
   if(upperPart / totalSize > 0.6 && bodySize / totalSize < 0.3) {
      isPinBar = true;
   }
   
   return isPinBar;
}

//+------------------------------------------------------------------+
//| Detect Wyckoff phase                                             |
//+------------------------------------------------------------------+
ENUM_WYCKOFF_PHASE CMarketStructure::DetectWyckoffPhase(int lookback) {
   // Reset spring/upthrust flags
   m_hasSpringPattern = false;
   m_hasUpthrustPattern = false;
   
   // Implement Wyckoff phase detection logic
   // Simplified implementation for demonstration
   double closes[], volumes[];
   double highestHigh = 0, lowestLow = 999999;
   double volumeSum = 0;
   
   ArrayResize(closes, lookback);
   ArrayResize(volumes, lookback);
   
   // Gather data
   for(int i = 0; i < lookback; i++) {
      closes[i] = iClose(m_symbol, m_timeframe, i);
      volumes[i] = iVolume(m_symbol, m_timeframe, i);
      highestHigh = MathMax(highestHigh, iHigh(m_symbol, m_timeframe, i));
      lowestLow = MathMin(lowestLow, iLow(m_symbol, m_timeframe, i));
      volumeSum += volumes[i];
   }
   
   // Calculate average volume
   double avgVolume = volumeSum / lookback;
   
   // Analysis
   double currentClose = closes[0];
   double currentVolume = volumes[0];
   
   // Check for spring pattern (break of support followed by higher close)
   for(int i = 1; i < lookback - 5; i++) {
      double prevLow = iLow(m_symbol, m_timeframe, i);
      double currentLow = iLow(m_symbol, m_timeframe, i-1);
      
      // Look for a break of previous low followed by price returning above it
      if(currentLow < prevLow && iClose(m_symbol, m_timeframe, i-1) > prevLow) {
         // Check if volume increased on the spring day
         if(iVolume(m_symbol, m_timeframe, i-1) > avgVolume * 1.3) {
            m_hasSpringPattern = true;
            break;
         }
      }
   }
   
   // Check for upthrust pattern (break of resistance followed by lower close)
   for(int i = 1; i < lookback - 5; i++) {
      double prevHigh = iHigh(m_symbol, m_timeframe, i);
      double currentHigh = iHigh(m_symbol, m_timeframe, i-1);
      
      // Look for a break of previous high followed by price returning below it
      if(currentHigh > prevHigh && iClose(m_symbol, m_timeframe, i-1) < prevHigh) {
         // Check if volume increased on the upthrust day
         if(iVolume(m_symbol, m_timeframe, i-1) > avgVolume * 1.3) {
            m_hasUpthrustPattern = true;
            break;
         }
      }
   }
   
   // Analyze volume and price patterns to determine Wyckoff phase
   // This is a simplified implementation
   
   // Check for accumulation phase
   bool hasLowVolumeSelloffs = false;
   bool hasHigherLows = true;
   
   for(int i = 10; i < lookback - 10 && i < 50; i++) {
      // Check for selling climax (sharp drop with high volume)
      if(closes[i] < closes[i+1] * 0.99 && volumes[i] > avgVolume * 1.5) {
         hasLowVolumeSelloffs = true;
      }
      
      // Check for higher lows
      if(i % 5 == 0) { // Check every 5 bars
         if(iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i+5)) {
            hasHigherLows = false;
            break;
         }
      }
   }
   
   if(m_hasSpringPattern && hasLowVolumeSelloffs && currentClose < highestHigh * 0.85) {
      m_currentWyckoffPhase = WYCKOFF_ACCUMULATION;
      return WYCKOFF_ACCUMULATION;
   }
   
   // Check for distribution phase
   bool hasLowVolumePushups = false;
   bool hasLowerHighs = true;
   
   for(int i = 10; i < lookback - 10 && i < 50; i++) {
      // Check for buying climax (sharp rise with high volume)
      if(closes[i] > closes[i+1] * 1.01 && volumes[i] > avgVolume * 1.5) {
         hasLowVolumePushups = true;
      }
      
      // Check for lower highs
      if(i % 5 == 0) { // Check every 5 bars
         if(iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i+5)) {
            hasLowerHighs = false;
            break;
         }
      }
   }
   
   if(m_hasUpthrustPattern && hasLowVolumePushups && currentClose > lowestLow * 1.15) {
      m_currentWyckoffPhase = WYCKOFF_DISTRIBUTION;
      return WYCKOFF_DISTRIBUTION;
   }
   
   // Check for markup phase
   if(currentClose > highestHigh * 0.95 && currentVolume > avgVolume * 1.2) {
      m_currentWyckoffPhase = WYCKOFF_MARKUP;
      return WYCKOFF_MARKUP;
   }
   
   // Check for markdown phase
   if(currentClose < lowestLow * 1.05 && currentVolume > avgVolume * 1.2) {
      m_currentWyckoffPhase = WYCKOFF_MARKDOWN;
      return WYCKOFF_MARKDOWN;
   }
   
   // No clear phase detected
   m_currentWyckoffPhase = WYCKOFF_NONE;
   return WYCKOFF_NONE;
}

//+------------------------------------------------------------------+
//| Check if current pattern is bullish                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBullishCandlePattern() {
   return m_lastPattern.candlePattern == PATTERN_BULLISH_ENGULFING ||
          m_lastPattern.candlePattern == PATTERN_MORNING_STAR ||
          m_lastPattern.candlePattern == PATTERN_HAMMER ||
          (m_lastPattern.candlePattern == PATTERN_PINBAR && m_lastPattern.patternDirection > 0);
}

//+------------------------------------------------------------------+
//| Check if current pattern is bearish                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBearishCandlePattern() {
   return m_lastPattern.candlePattern == PATTERN_BEARISH_ENGULFING ||
          m_lastPattern.candlePattern == PATTERN_EVENING_STAR ||
          m_lastPattern.candlePattern == PATTERN_SHOOTING_STAR ||
          (m_lastPattern.candlePattern == PATTERN_PINBAR && m_lastPattern.patternDirection < 0);
}

//+------------------------------------------------------------------+
//| Set sensitivity levels for pattern detection                      |
//+------------------------------------------------------------------+
void CMarketStructure::SetPatternSensitivity(int candleSensitivity, int harmonicSensitivity, int wyckoffSensitivity) {
   // Ensure values are within valid range
   m_candlePatternSensitivity = MathMax(1, MathMin(10, candleSensitivity));
   m_harmonicPatternSensitivity = MathMax(1, MathMin(10, harmonicSensitivity));
   m_wyckoffSensitivity = MathMax(1, MathMin(10, wyckoffSensitivity));
}

//+------------------------------------------------------------------+
//| Calculate current market volatility                              |
//+------------------------------------------------------------------+
double CMarketStructure::CalculateVolatility() {
   // Use ATR as volatility measure
   double currentATR = m_atr;
   
   // Calculate ATR relative to its average over a longer period
   double atrSum = 0;
   double atrArray[];
   ArraySetAsSeries(atrArray, true);
   
   int atrHandle = iATR(m_symbol, m_timeframe, m_atrPeriod);
   if(atrHandle != INVALID_HANDLE) {
      if(CopyBuffer(atrHandle, 0, 0, 20, atrArray) > 0) {
         for(int i = 0; i < 20; i++) {
            atrSum += atrArray[i];
         }
      }
      IndicatorRelease(atrHandle);
   }
   
   double avgATR = atrSum / 20;
   
   // Return ratio of current ATR to average ATR
   if(avgATR > 0)
      return currentATR / avgATR;
   else
      return 1.0;
}

//+------------------------------------------------------------------+
//| Phân tích chế độ thị trường                                       |
//+------------------------------------------------------------------+
ENUM_MARKET_MODE CMarketStructure::GetMarketMode() {
   ENUM_MARKET_STRUCTURE structure = GetMarketStructure();
   double hurstValue = m_hurstInfo.value;
   double volatility = GetVolatility();
   bool isBreakout = IsBreakout();
   
   // Xác định chế độ thị trường dựa vào cấu trúc và Hurst exponent
   if(structure == MARKET_STRONG_UPTREND || structure == MARKET_STRONG_DOWNTREND) {
      if(isBreakout)
         return MARKET_MODE_VOLATILE; // Đột phá trong xu hướng mạnh thường có biến động cao
      else
         return MARKET_MODE_TRENDING; // Xu hướng rõ ràng
   }
   else if(structure == MARKET_RANGING) {
      return MARKET_MODE_RANGING; // Thị trường đi ngang
   }
   else if(structure == MARKET_VOLATILE || volatility > 1.5) {
      return MARKET_MODE_VOLATILE; // Thị trường biến động
   }
   else if(IsPotentialReversal()) {
      return MARKET_MODE_REVERSAL; // Có dấu hiệu đảo chiều
   }
   
   // Dựa vào Hurst
   if(hurstValue > 0.6) // Xu hướng mạnh
      return MARKET_MODE_TRENDING;
   else if(hurstValue < 0.4) // Đảo chiều mạnh
      return MARKET_MODE_REVERSAL;
   else if(hurstValue >= 0.45 && hurstValue <= 0.55) // Trung tính
      return MARKET_MODE_RANGING;
   
   // Mặc định
   return MARKET_MODE_UNKNOWN;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có đột phá thị trường không                         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBreakout() {
   // Đọc giá trị mới nhất
   double high = iHigh(m_symbol, m_timeframe, 0);
   double low = iLow(m_symbol, m_timeframe, 0);
   double close = iClose(m_symbol, m_timeframe, 0);
   
   // Tính toán các ngưỡng ATR
   double atr = GetATR();
   
   // Tìm giá cao nhất và thấp nhất trong 20 nến
   double highestHigh = 0;
   double lowestLow = DBL_MAX;
   
   for(int i = 1; i < 20; i++) {
      highestHigh = MathMax(highestHigh, iHigh(m_symbol, m_timeframe, i));
      lowestLow = MathMin(lowestLow, iLow(m_symbol, m_timeframe, i));
   }
   
   // Kiểm tra đột phá lên
   if(close > highestHigh + atr * 0.5)
      return true;
   
   // Kiểm tra đột phá xuống
   if(close < lowestLow - atr * 0.5)
      return true;
   
   // Kiểm tra đột phá Bollinger Bands
   if(close > m_bollUpper + atr * 0.3 || close < m_bollLower - atr * 0.3)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Lấy giá trị Hurst Exponent hiện tại                              |
//+------------------------------------------------------------------+
double CMarketStructure::GetHurstExponent() {
   return m_hurstInfo.value;
}

//+------------------------------------------------------------------+
//| Check if we have a Higher Highs & Higher Lows structure          |
//+------------------------------------------------------------------+
bool CMarketStructure::HasHigherHighsHigherLows() const {
   // Kiểm tra 3 đỉnh và 3 đáy gần nhất
   int swingCount = 5;
   double highs[5], lows[5];
   
   // Tìm các đỉnh và đáy
   for(int i = 0; i < swingCount; i++) {
      // Chiến lược đơn giản: tìm đỉnh trong 3 nến và đáy trong 3 nến
      int start = i * 10; // Cách nhau 10 nến
      
      double highestHigh = iHigh(m_symbol, m_timeframe, start);
      double lowestLow = iLow(m_symbol, m_timeframe, start);
      
      for(int j = start+1; j < start+3; j++) {
         highestHigh = MathMax(highestHigh, iHigh(m_symbol, m_timeframe, j));
         lowestLow = MathMin(lowestLow, iLow(m_symbol, m_timeframe, j));
      }
      
      highs[i] = highestHigh;
      lows[i] = lowestLow;
   }
   
   // Kiểm tra xem có hình thành HHHLS (Higher Highs Higher Lows)
   bool hasHHHLs = true;
   
   for(int i = 1; i < swingCount-1; i++) {
      if(highs[i] <= highs[i+1] || lows[i] <= lows[i+1]) {
         hasHHHLs = false;
         break;
      }
   }
   
   return hasHHHLs;
}

//+------------------------------------------------------------------+
//| Check if we have a Lower Lows & Lower Highs structure            |
//+------------------------------------------------------------------+
bool CMarketStructure::HasLowerLowsLowerHighs() const {
   // Kiểm tra 3 đỉnh và 3 đáy gần nhất
   int swingCount = 5;
   double highs[5], lows[5];
   
   // Tìm các đỉnh và đáy
   for(int i = 0; i < swingCount; i++) {
      // Chiến lược đơn giản: tìm đỉnh trong 3 nến và đáy trong 3 nến
      int start = i * 10; // Cách nhau 10 nến
      
      double highestHigh = iHigh(m_symbol, m_timeframe, start);
      double lowestLow = iLow(m_symbol, m_timeframe, start);
      
      for(int j = start+1; j < start+3; j++) {
         highestHigh = MathMax(highestHigh, iHigh(m_symbol, m_timeframe, j));
         lowestLow = MathMin(lowestLow, iLow(m_symbol, m_timeframe, j));
      }
      
      highs[i] = highestHigh;
      lows[i] = lowestLow;
   }
   
   // Kiểm tra xem có hình thành LLLHS (Lower Lows Lower Highs)
   bool hasLLLHs = true;
   
   for(int i = 1; i < swingCount-1; i++) {
      if(highs[i] >= highs[i+1] || lows[i] >= lows[i+1]) {
         hasLLLHs = false;
         break;
      }
   }
   
   return hasLLLHs;
}

//+------------------------------------------------------------------+
//| Check if we have a bullish trend based on price and Hurst         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBullishTrend() const {
   // Kiểm tra xu hướng giá
   bool priceUptrend = m_emaFast > m_emaMedium && m_emaMedium > m_emaLong;
   
   // Kiểm tra Hurst
   bool hurstUptrend = m_hurstInfo.value > 0.55 && m_hurstAlignedTrending;
   
   // Kết hợp các yếu tố
   return priceUptrend && hurstUptrend;
}

//+------------------------------------------------------------------+
//| Check if we have a bearish trend based on price and Hurst         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBearishTrend() const {
   // Kiểm tra xu hướng giá
   bool priceDowntrend = m_emaFast < m_emaMedium && m_emaMedium < m_emaLong;
   
   // Kiểm tra Hurst
   bool hurstDowntrend = m_hurstInfo.value > 0.55 && m_hurstAlignedTrending;
   
   // Kết hợp các yếu tố
   return priceDowntrend && hurstDowntrend;
}

//+------------------------------------------------------------------+
//| Update Hurst Analysis with new approach                           |
//+------------------------------------------------------------------+
void CMarketStructure::UpdateHurstAnalysis() {
   if(m_hurstAnalysis == NULL) return;
   
   // Cập nhật Hurst đa tầng
   m_hurstAnalysis.CalculateMultiTimeframe(m_symbol, m_shortTermHurst, m_mediumTermHurst, m_longTermHurst);
   
   // Kiểm tra phân kỳ Hurst
   bool isBullish = false;
   if(m_hurstAnalysis.DetectHurstDivergence(m_symbol, m_timeframe, isBullish)) {
      m_hurstDivergenceBullish = isBullish;
      m_hurstDivergenceBearish = !isBullish;
   } else {
      m_hurstDivergenceBullish = false;
      m_hurstDivergenceBearish = false;
   }
   
   // Kiểm tra sự đồng thuận giữa các khung thời gian Hurst
   bool isTrending = false;
   bool isMeanReverting = false;
   if(m_hurstAnalysis.IsHurstAligned(m_symbol, m_timeframe, isTrending, isMeanReverting)) {
      m_hurstAlignedTrending = isTrending;
      m_hurstAlignedReverting = isMeanReverting;
   } else {
      m_hurstAlignedTrending = false;
      m_hurstAlignedReverting = false;
   }
   
   // Tính xác suất thay đổi chế độ thị trường
   m_regimeChangeProbability = m_hurstAnalysis.GetRegimeChangeProbability(m_symbol, m_timeframe);
}

//+------------------------------------------------------------------+
//| Update Hurst multi-timeframe analysis                             |
//+------------------------------------------------------------------+
void CMarketStructure::UpdateMultiTimeframeHurst() {
   // Gọi phương thức đa tầng Hurst
   if(m_hurstAnalysis != NULL) {
      m_hurstAnalysis.CalculateMultiTimeframe(m_symbol, m_shortTermHurst, m_mediumTermHurst, m_longTermHurst);
   }
}

//+------------------------------------------------------------------+
//| Check if market is trending                                       |
//+------------------------------------------------------------------+
bool CMarketStructure::IsTrending() {
   return m_adx > m_adxThreshold && 
          MathAbs(m_emaFast - m_emaLong) > m_atr * 2;
}

//+------------------------------------------------------------------+
//| Check if market is ranging                                        |
//+------------------------------------------------------------------+
bool CMarketStructure::IsRanging() {
   // Ranging markets typically have low ADX
   if(m_adx > m_adxThreshold)
      return false;
   
   // Check if price is oscillating between bollinger bands
   double close = iClose(m_symbol, m_timeframe, 0);
   double bollWidth = (m_bollUpper - m_bollLower) / m_bollMiddle;
   
   return bollWidth < 0.05 || // Narrow bands
          (MathAbs(m_emaFast - m_emaMedium) < m_atr * 0.5 && 
           MathAbs(m_emaMedium - m_emaLong) < m_atr * 1.0);
}

//+------------------------------------------------------------------+
//| Check if market is volatile                                       |
//+------------------------------------------------------------------+
bool CMarketStructure::IsVolatile() {
   return m_volatility > m_volatilityThreshold * 1.5 || // Extremely high volatility
          m_atr > m_maxATRForNormalTrading;
}

//+------------------------------------------------------------------+
//| Check if market is choppy                                         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsChoppy() {
   // Choppy markets have low ADX and frequent crosses of fast/medium EMAs
   if(m_adx > m_adxThreshold)
      return false;
   
   // Check EMA crosses in recent bars
   int crossCount = 0;
   double prevFast, prevMedium;
   
   for(int i = 1; i < 10; i++) {
      prevFast = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
      prevMedium = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
      
      double nextFast = iMA(m_symbol, m_timeframe, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE, i-1);
      double nextMedium = iMA(m_symbol, m_timeframe, m_emaMediumPeriod, 0, MODE_EMA, PRICE_CLOSE, i-1);
      
      if((prevFast > prevMedium && nextFast < nextMedium) || 
         (prevFast < prevMedium && nextFast > nextMedium)) {
         crossCount++;
      }
   }
   
   return crossCount >= 2; // At least 2 crosses in 10 bars = choppy
}

//+------------------------------------------------------------------+
//| Check if market is overbought                                     |
//+------------------------------------------------------------------+
bool CMarketStructure::IsOverbought() {
   return (m_rsi > m_rsiOverbought) && 
          iClose(m_symbol, m_timeframe, 0) > m_bollUpper;
}

//+------------------------------------------------------------------+
//| Check if market is oversold                                       |
//+------------------------------------------------------------------+
bool CMarketStructure::IsOversold() {
   return (m_rsi < m_rsiOversold) && 
          iClose(m_symbol, m_timeframe, 0) < m_bollLower;
}

//+------------------------------------------------------------------+
//| Check for bullish divergence                                      |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBullishDivergence(int lookbackBars) {
   double lowestLow = DBL_MAX;
   double lowestRSI = DBL_MAX;
   int lowestLowBar = -1;
   int lowestRSIBar = -1;
   
   // Find lowest low and corresponding RSI in lookback period
   for(int i = 0; i < lookbackBars; i++) {
      double low = iLow(m_symbol, m_timeframe, i);
      double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
      
      if(low < lowestLow) {
         lowestLow = low;
         lowestLowBar = i;
      }
      
      if(rsi < lowestRSI) {
         lowestRSI = rsi;
         lowestRSIBar = i;
      }
   }
   
   // Look for a second low that's lower than the first but with higher RSI
   if(lowestLowBar > 0 && lowestRSIBar > 0) {
      for(int i = 0; i < lookbackBars; i++) {
         if(i != lowestLowBar) {
            double low = iLow(m_symbol, m_timeframe, i);
            double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
            
            // Check for lower low with higher RSI
            if(low < lowestLow && rsi > lowestRSI) {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for bearish divergence                                      |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBearishDivergence(int lookbackBars) {
   double highestHigh = -DBL_MAX;
   double highestRSI = -DBL_MAX;
   int highestHighBar = -1;
   int highestRSIBar = -1;
   
   // Find highest high and corresponding RSI in lookback period
   for(int i = 0; i < lookbackBars; i++) {
      double high = iHigh(m_symbol, m_timeframe, i);
      double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
      
      if(high > highestHigh) {
         highestHigh = high;
         highestHighBar = i;
      }
      
      if(rsi > highestRSI) {
         highestRSI = rsi;
         highestRSIBar = i;
      }
   }
   
   // Look for a second high that's higher than the first but with lower RSI
   if(highestHighBar > 0 && highestRSIBar > 0) {
      for(int i = 0; i < lookbackBars; i++) {
         if(i != highestHighBar) {
            double high = iHigh(m_symbol, m_timeframe, i);
            double rsi = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE, i);
            
            // Check for higher high with lower RSI
            if(high > highestHigh && rsi < highestRSI) {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for potential price reversal                               |
//+------------------------------------------------------------------+
bool CMarketStructure::IsPotentialReversal() {
   ENUM_MARKET_STRUCTURE currentStructure = GetMarketStructure();
   
   // Check if market is in trend
   if(currentStructure == MARKET_STRONG_UPTREND || currentStructure == MARKET_WEAK_UPTREND) {
      // Check for bearish divergence or overbought in uptrend
      return IsBearishDivergence(20) || IsOverbought();
   }
   else if(currentStructure == MARKET_STRONG_DOWNTREND || currentStructure == MARKET_WEAK_DOWNTREND) {
      // Check for bullish divergence or oversold in downtrend
      return IsBullishDivergence(20) || IsOversold();
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for breakout                                               |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBreakout() {
   double close = iClose(m_symbol, m_timeframe, 0);
   double prev_close = iClose(m_symbol, m_timeframe, 1);
   
   // Check for price breaking above/below Bollinger Bands with volume
   if((close > m_bollUpper && prev_close <= m_bollUpper) || 
      (close < m_bollLower && prev_close >= m_bollLower)) {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get current market bias                                          |
//+------------------------------------------------------------------+
int CMarketStructure::GetBias() {
   ENUM_MARKET_STRUCTURE currentStructure = GetMarketStructure();
   
   // Determine bias based on market structure
   switch(currentStructure) {
      case MARKET_STRONG_UPTREND:
      case MARKET_WEAK_UPTREND:
         return 1;   // Bullish
         
      case MARKET_STRONG_DOWNTREND:
      case MARKET_WEAK_DOWNTREND:
         return -1;  // Bearish
         
      case MARKET_RANGING:
         // In ranging market, check if we're near support/resistance
         if(iClose(m_symbol, m_timeframe, 0) > m_bollMiddle)
            return 1;   // Upper half of range
         else
            return -1;  // Lower half of range
         
      case MARKET_VOLATILE:
      case MARKET_CHOPPY:
      case MARKET_UNKNOWN:
      default:
         return 0;   // Neutral
   }
}

//+------------------------------------------------------------------+
//| Get volatility level compared to historical                      |
//+------------------------------------------------------------------+
double CMarketStructure::GetVolatilityLevel() {
   return m_volatility;
}

//+------------------------------------------------------------------+
//| Update settings                                                  |
//+------------------------------------------------------------------+
void CMarketStructure::UpdateSettings(
   int rsiPeriod,
   int adxPeriod,
   double adxThreshold,
   int emaFastPeriod,
   int emaMediumPeriod,
   int emaLongPeriod
) {
   m_rsiPeriod = rsiPeriod;
   m_adxPeriod = adxPeriod;
   m_adxThreshold = adxThreshold;
   m_emaFastPeriod = emaFastPeriod;
   m_emaMediumPeriod = emaMediumPeriod;
   m_emaLongPeriod = emaLongPeriod;
   
   // Update indicators with new settings
   UpdateIndicators();
}

//+------------------------------------------------------------------+
//| Xác định các đỉnh và đáy quan trọng                              |
//+------------------------------------------------------------------+
void CMarketStructure::IdentifySwingHighsLows(int &highPoints[], int &lowPoints[], int &highCount, int &lowCount, int maxBars) {
   highCount = 0;
   lowCount = 0;
   
   // Xác định các đỉnh
   for(int i = 2; i < maxBars - 2; i++) {
      // Kiểm tra đỉnh
      if(iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i-1) &&
         iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i-2) &&
         iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i+1) &&
         iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i+2)) {
         
         // Thêm vào mảng đỉnh
         if(highCount < ArraySize(highPoints)) {
            highPoints[highCount] = i;
            highCount++;
         }
      }
      
      // Kiểm tra đáy
      if(iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i-1) &&
         iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i-2) &&
         iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i+1) &&
         iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i+2)) {
         
         // Thêm vào mảng đáy
         if(lowCount < ArraySize(lowPoints)) {
            lowPoints[lowCount] = i;
            lowCount++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Tính giá tại thời điểm trên trendline                           |
//+------------------------------------------------------------------+
double CMarketStructure::CalculateTrendlinePrice(const TrendlineInfo &tl, datetime time) {
   if(!tl.isValid) return 0;
   
   // Tính slope và intercept
   double timeRange = (double)(tl.time2 - tl.time1);
   if(timeRange == 0) return 0; // Tránh chia cho 0
   
   double slope = (tl.price2 - tl.price1) / timeRange;
   double intercept = tl.price1 - slope * (double)(tl.time1);
   
   // Tính giá tại thời điểm
   return slope * (double)(time) + intercept;
}

//+------------------------------------------------------------------+
//| Xác định trendline trên và dưới quan trọng nhất                  |
//+------------------------------------------------------------------+
void CMarketStructure::IdentifyKeyTrendlines() {
   // Reset thông tin
   m_upperTrendline.isValid = false;
   m_lowerTrendline.isValid = false;
   
   // Xác định các đỉnh và đáy tiềm năng
   int highPoints[10], lowPoints[10];
   int highCount = 0, lowCount = 0;
   
   // Tìm các đỉnh và đáy quan trọng trong 200 nến
   ArrayResize(highPoints, 10);
   ArrayResize(lowPoints, 10);
   IdentifySwingHighsLows(highPoints, lowPoints, highCount, lowCount, 200);
   
   // Tìm trendline trên (kết nối các đỉnh)
   if(highCount >= 2) {
      // Thử kết nối các đỉnh khác nhau để tìm trendline mạnh nhất
      double bestStrength = 0;
      for(int i = 0; i < highCount - 1; i++) {
         for(int j = i + 1; j < highCount; j++) {
            TrendlineInfo tempTL;
            tempTL.time1 = iTime(m_symbol, m_timeframe, highPoints[i]);
            tempTL.time2 = iTime(m_symbol, m_timeframe, highPoints[j]);
            tempTL.price1 = iHigh(m_symbol, m_timeframe, highPoints[i]);
            tempTL.price2 = iHigh(m_symbol, m_timeframe, highPoints[j]);
            tempTL.isValid = true;
            
            // Đếm số điểm chạm và kiểm tra đường thẳng có hợp lệ
            double strength = ValidateTrendline(tempTL, true);
            
            if(strength > bestStrength) {
               bestStrength = strength;
               m_upperTrendline = tempTL;
               m_upperTrendline.isValid = true;
               m_upperTrendline.strength = strength;
            }
         }
      }
   }
   
   // Tìm trendline dưới (kết nối các đáy)
   if(lowCount >= 2) {
      double bestStrength = 0;
      for(int i = 0; i < lowCount - 1; i++) {
         for(int j = i + 1; j < lowCount; j++) {
            TrendlineInfo tempTL;
            tempTL.time1 = iTime(m_symbol, m_timeframe, lowPoints[i]);
            tempTL.time2 = iTime(m_symbol, m_timeframe, lowPoints[j]);
            tempTL.price1 = iLow(m_symbol, m_timeframe, lowPoints[i]);
            tempTL.price2 = iLow(m_symbol, m_timeframe, lowPoints[j]);
            tempTL.isValid = true;
            
            // Đếm số điểm chạm và kiểm tra đường thẳng có hợp lệ
            double strength = ValidateTrendline(tempTL, false);
            
            if(strength > bestStrength) {
               bestStrength = strength;
               m_lowerTrendline = tempTL;
               m_lowerTrendline.isValid = true;
               m_lowerTrendline.strength = strength;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra trendline có bao nhiêu điểm chạm và tính độ mạnh        |
//+------------------------------------------------------------------+
double CMarketStructure::ValidateTrendline(TrendlineInfo &tl, bool isUpper, int maxBars) {
   if(!tl.isValid) return 0;
   
   int touchCount = 0;
   double tolerance = m_atr * 0.5; // Dung sai bằng nửa ATR
   datetime lastTouchTime = 0;
   
   // Kiểm tra từng thanh nến xem có chạm trendline không
   for(int i = 0; i < maxBars; i++) {
      datetime barTime = iTime(m_symbol, m_timeframe, i);
      double linePrice = CalculateTrendlinePrice(tl, barTime);
      
      if(isUpper) {
         if(MathAbs(iHigh(m_symbol, m_timeframe, i) - linePrice) <= tolerance) {
            touchCount++;
            lastTouchTime = barTime;
         }
      } else {
         if(MathAbs(iLow(m_symbol, m_timeframe, i) - linePrice) <= tolerance) {
            touchCount++;
            lastTouchTime = barTime;
         }
      }
   }
   
   tl.touchPoints = touchCount;
   tl.lastTouch = lastTouchTime;
   
   // Tính độ mạnh dựa trên số điểm chạm và khoảng thời gian
   double timeStrength = (tl.time1 - tl.time2) / (60.0 * 60.0 * 24.0); // Số ngày
   if(timeStrength < 0) timeStrength = -timeStrength;
   
   return touchCount * 0.8 + timeStrength * 0.2; // Tính điểm độ mạnh
}

//+------------------------------------------------------------------+
//| Phát hiện kênh giá                                               |
//+------------------------------------------------------------------+
bool CMarketStructure::DetectPriceChannel() {
   // Kiểm tra hai trendline có tồn tại và hợp lệ
   if(!m_upperTrendline.isValid || !m_lowerTrendline.isValid) {
      return false;
   }
   
   // Kiểm tra hai trendline có song song không
   double slope1 = (m_upperTrendline.price2 - m_upperTrendline.price1) / 
                  (double)(m_upperTrendline.time2 - m_upperTrendline.time1);
   
   double slope2 = (m_lowerTrendline.price2 - m_lowerTrendline.price1) / 
                  (double)(m_lowerTrendline.time2 - m_lowerTrendline.time1);
   
   // Nếu độ dốc tương đối gần nhau (song song)
   if(MathAbs(slope1 - slope2) < 0.0001) {
      datetime currentTime = TimeCurrent();
      m_upperChannel = CalculateTrendlinePrice(m_upperTrendline, currentTime);
      m_lowerChannel = CalculateTrendlinePrice(m_lowerTrendline, currentTime);
      m_channelWidth = m_upperChannel - m_lowerChannel;
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Phát hiện mô hình tam giác                                       |
//+------------------------------------------------------------------+
ENUM_TRIANGLE_TYPE CMarketStructure::DetectTrianglePattern() {
   if(!m_upperTrendline.isValid || !m_lowerTrendline.isValid) 
      return TRIANGLE_NONE;
   
   // Tính độ dốc hai đường
   double upperSlope = (m_upperTrendline.price2 - m_upperTrendline.price1) / 
                      (double)(m_upperTrendline.time2 - m_upperTrendline.time1);
   
   double lowerSlope = (m_lowerTrendline.price2 - m_lowerTrendline.price1) / 
                      (double)(m_lowerTrendline.time2 - m_lowerTrendline.time1);
   
   // Tam giác đối xứng (cả hai đường hướng vào nhau)
   if(upperSlope < -0.0001 && lowerSlope > 0.0001) {
      return TRIANGLE_SYMMETRICAL;
   }
   
   // Tam giác tăng (đường dưới đi lên, đường trên ngang)
   if(MathAbs(upperSlope) < 0.0001 && lowerSlope > 0.0001) {
      return TRIANGLE_ASCENDING;
   }
   
   // Tam giác giảm (đường trên đi xuống, đường dưới ngang)
   if(upperSlope < -0.0001 && MathAbs(lowerSlope) < 0.0001) {
      return TRIANGLE_DESCENDING;
   }
   
   return TRIANGLE_NONE;
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu giá gần trendline hỗ trợ                            |
//+------------------------------------------------------------------+
bool CMarketStructure::IsSupportTrendlineNearby(int pipsThreshold) {
   if(!m_lowerTrendline.isValid) return false;
   
   double currentPrice = iClose(m_symbol, m_timeframe, 0);
   datetime currentTime = TimeCurrent();
   double supportPrice = CalculateTrendlinePrice(m_lowerTrendline, currentTime);
   
   double distance = MathAbs(currentPrice - supportPrice);
   double thresholdInPrice = PipsToPrice(m_symbol, (double)pipsThreshold);
   
   return (distance <= thresholdInPrice);
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu giá gần trendline kháng cự                          |
//+------------------------------------------------------------------+
bool CMarketStructure::IsResistanceTrendlineNearby(int pipsThreshold) {
   if(!m_upperTrendline.isValid) return false;
   
   double currentPrice = iClose(m_symbol, m_timeframe, 0);
   datetime currentTime = TimeCurrent();
   double resistancePrice = CalculateTrendlinePrice(m_upperTrendline, currentTime);
   
   double distance = MathAbs(currentPrice - resistancePrice);
   double thresholdInPrice = PipsToPrice(m_symbol, (double)pipsThreshold);
   
   return (distance <= thresholdInPrice);
}

//+------------------------------------------------------------------+
//| Kiểm tra đột phá mô hình giá                                     |
//+------------------------------------------------------------------+
bool CMarketStructure::CheckPatternBreakout(bool &isBullish) {
   // 1. Kiểm tra đột phá kênh giá
   if(m_hasValidChannel) {
      double currentPrice = iClose(m_symbol, m_timeframe, 0);
      
      // Xác nhận đột phá kênh (cần xác nhận rõ ràng)
      if(currentPrice > m_upperChannel + (m_channelWidth * 0.03)) {
         isBullish = true;
         return true;
      }
      else if(currentPrice < m_lowerChannel - (m_channelWidth * 0.03)) {
         isBullish = false;
         return true;
      }
   }
   
   // 2. Kiểm tra đột phá mô hình tam giác
   if(m_triangleType != TRIANGLE_NONE) {
      // Tính điểm hội tụ của tam giác
      double convergencePrice = 0;
      datetime convergenceTime = 0;
      
      // TODO: Tính toán điểm hội tụ và kiểm tra đột phá
   }
   
   // 3. Kiểm tra giá chạm trendline quan trọng
   double currentPrice = iClose(m_symbol, m_timeframe, 0);
   datetime currentTime = TimeCurrent();
   
   if(m_upperTrendline.isValid) {
      double upperPrice = CalculateTrendlinePrice(m_upperTrendline, currentTime);
      // Kiểm tra nếu giá đang test trendline trên
      if(MathAbs(currentPrice - upperPrice) < m_atr * 0.3) {
         // Xác nhận với Hurst để tìm cơ hội Short
         if(m_hurstInfo.value < 0.45) {
            isBullish = false;
            return true;
         }
      }
   }
   
   if(m_lowerTrendline.isValid) {
      double lowerPrice = CalculateTrendlinePrice(m_lowerTrendline, currentTime);
      // Kiểm tra nếu giá đang test trendline dưới
      if(MathAbs(currentPrice - lowerPrice) < m_atr * 0.3) {
         // Xác nhận với Hurst để tìm cơ hội Long
         if(m_hurstInfo.value > 0.55) {
            isBullish = true;
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Initialize Hurst Analysis component                              |
//+------------------------------------------------------------------+
void CMarketStructure::InitializeHurstAnalysis(
   int hurstPeriod,
   double hurstTrendThreshold,
   double hurstMeanRevThreshold
) {
   // Create Hurst Analysis object if not exists
   if(m_hurstAnalysis == NULL) {
      m_hurstAnalysis = new CHurstAnalysis(
         hurstPeriod,
         hurstTrendThreshold,
         hurstMeanRevThreshold
      );
   } else {
      // Update settings if already exists
      m_hurstAnalysis.SetParameters(
         hurstPeriod,
         hurstTrendThreshold,
         hurstMeanRevThreshold,
         true, // Adaptive thresholds
         70,   // Min reliability
         1.2   // Sensitivity
      );
   }
   
   // Calculate initial Hurst value
   m_hurstInfo = m_hurstAnalysis.CalculateForSymbol(m_symbol, m_timeframe, hurstPeriod);
}

//+------------------------------------------------------------------+
//| Update pattern recognition                                        |
//+------------------------------------------------------------------+
void CMarketStructure::UpdatePatternRecognition() {
   // Detect patterns
   m_lastPattern.candlePattern = DetectCandlePattern();
   m_lastPattern.harmonicPattern = DetectHarmonicPattern();
   m_lastPattern.wyckoffPhase = DetectWyckoffPhase();
   m_lastPattern.detectionTime = TimeCurrent();
   
   // Calculate overall pattern strength and direction
   int candleStrength = 0;
   int harmonicStrength = 0;
   int wyckoffStrength = 0;
   int candleDirection = 0;
   int harmonicDirection = 0;
   int wyckoffDirection = 0;
   
   // Analyze candle patterns
   switch(m_lastPattern.candlePattern) {
      case PATTERN_BULLISH_ENGULFING:
         candleStrength = 70;
         candleDirection = 1;
         m_lastPattern.patternDescription = "Bullish Engulfing";
         break;
      case PATTERN_BEARISH_ENGULFING:
         candleStrength = 70;
         candleDirection = -1;
         m_lastPattern.patternDescription = "Bearish Engulfing";
         break;
      case PATTERN_MORNING_STAR:
         candleStrength = 85;
         candleDirection = 1;
         m_lastPattern.patternDescription = "Morning Star";
         break;
      case PATTERN_EVENING_STAR:
         candleStrength = 85;
         candleDirection = -1;
         m_lastPattern.patternDescription = "Evening Star";
         break;
      case PATTERN_HAMMER:
         candleStrength = 60;
         candleDirection = 1;
         m_lastPattern.patternDescription = "Hammer";
         break;
      case PATTERN_SHOOTING_STAR:
         candleStrength = 60;
         candleDirection = -1;
         m_lastPattern.patternDescription = "Shooting Star";
         break;
      case PATTERN_PINBAR:
         double close = iClose(m_symbol, m_timeframe, 0);
         double open = iOpen(m_symbol, m_timeframe, 0);
         candleStrength = 75;
         candleDirection = (close > open) ? 1 : -1;
         m_lastPattern.patternDescription = "Pin Bar";
         break;
      default:
         candleStrength = 0;
         candleDirection = 0;
         break;
   }
   
   // Analyze Wyckoff phases
   switch(m_lastPattern.wyckoffPhase) {
      case WYCKOFF_ACCUMULATION:
         wyckoffStrength = 80;
         wyckoffDirection = 1; // Preparing for markup
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Accumulation";
         break;
      case WYCKOFF_DISTRIBUTION:
         wyckoffStrength = 80;
         wyckoffDirection = -1; // Preparing for markdown
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Distribution";
         break;
      case WYCKOFF_MARKUP:
         wyckoffStrength = 60;
         wyckoffDirection = 1;
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Markup";
         break;
      case WYCKOFF_MARKDOWN:
         wyckoffStrength = 60;
         wyckoffDirection = -1;
         m_lastPattern.patternDescription += (m_lastPattern.patternDescription != "" ? ", " : "") + "Wyckoff Markdown";
         break;
      default:
         wyckoffStrength = 0;
         wyckoffDirection = 0;
         break;
   }
   
   // If no description, add a default one
   if(m_lastPattern.patternDescription == "")
      m_lastPattern.patternDescription = "No significant pattern";
   
   // Calculate weighted average of pattern strength and direction
   double totalStrength = candleStrength * 0.4 + harmonicStrength * 0.3 + wyckoffStrength * 0.3;
   
   // Only assign a direction if enough patterns agree
   if(candleDirection != 0 && wyckoffDirection != 0) {
      if(candleDirection == wyckoffDirection)
         m_lastPattern.patternDirection = candleDirection;
      else
         m_lastPattern.patternDirection = (candleStrength > wyckoffStrength) ? candleDirection : wyckoffDirection;
   }
   else if(candleDirection != 0)
      m_lastPattern.patternDirection = candleDirection;
   else if(wyckoffDirection != 0)
      m_lastPattern.patternDirection = wyckoffDirection;
   else
      m_lastPattern.patternDirection = 0;
   
   m_lastPattern.patternStrength = (int)MathRound(totalStrength);
}

//+------------------------------------------------------------------+
//| Detect candle patterns                                           |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CMarketStructure::DetectCandlePattern(int startBar, int lookback) {
   // Check for various candle patterns, starting with the strongest ones
   if(IsMorningStar(startBar))
      return PATTERN_MORNING_STAR;
      
   if(IsEveningStar(startBar))
      return PATTERN_EVENING_STAR;
      
   if(IsBullishEngulfing(startBar))
      return PATTERN_BULLISH_ENGULFING;
      
   if(IsBearishEngulfing(startBar))
      return PATTERN_BEARISH_ENGULFING;
      
   if(IsPinBar(startBar))
      return PATTERN_PINBAR;
      
   if(IsHammer(startBar))
      return PATTERN_HAMMER;
      
   if(IsShootingStar(startBar))
      return PATTERN_SHOOTING_STAR;
      
   if(IsDoji(startBar))
      return PATTERN_DOJI;
   
   return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Check for bullish engulfing pattern                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBullishEngulfing(int shift) {
   double currOpen = iOpen(m_symbol, m_timeframe, shift);
   double currClose = iClose(m_symbol, m_timeframe, shift);
   double prevOpen = iOpen(m_symbol, m_timeframe, shift + 1);
   double prevClose = iClose(m_symbol, m_timeframe, shift + 1);
   
   // Basic bullish engulfing pattern
   if(currClose > currOpen && // Current candle is bullish
      prevClose < prevOpen && // Previous candle is bearish
      currOpen < prevClose && // Current open is lower than previous close
      currClose > prevOpen)   // Current close is higher than previous open
   {
      // Check for additional confirmation
      double bodySize = MathAbs(currClose - currOpen);
      double prevBodySize = MathAbs(prevClose - prevOpen);
      
      // Current body should be larger than previous body
      if(bodySize > prevBodySize * (1.0 + 0.1 * m_candlePatternSensitivity))
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for bearish engulfing pattern                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBearishEngulfing(int shift) {
   double currOpen = iOpen(m_symbol, m_timeframe, shift);
   double currClose = iClose(m_symbol, m_timeframe, shift);
   double prevOpen = iOpen(m_symbol, m_timeframe, shift + 1);
   double prevClose = iClose(m_symbol, m_timeframe, shift + 1);
   
   // Basic bearish engulfing pattern
   if(currClose < currOpen && // Current candle is bearish
      prevClose > prevOpen && // Previous candle is bullish
      currOpen > prevClose && // Current open is higher than previous close
      currClose < prevOpen)   // Current close is lower than previous open
   {
      // Check for additional confirmation
      double bodySize = MathAbs(currClose - currOpen);
      double prevBodySize = MathAbs(prevClose - prevOpen);
      
      // Current body should be larger than previous body
      if(bodySize > prevBodySize * (1.0 + 0.1 * m_candlePatternSensitivity))
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for morning star pattern                                   |
//+------------------------------------------------------------------+
bool CMarketStructure::IsMorningStar(int shift) {
   if(shift + 2 >= Bars(m_symbol, m_timeframe)) return false;
   
   // First candle: bearish
   bool firstBearish = iClose(m_symbol, m_timeframe, shift + 2) < iOpen(m_symbol, m_timeframe, shift + 2);
   
   // Second candle: small body (doji or small candle)
   double secondBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 1) - iOpen(m_symbol, m_timeframe, shift + 1));
   bool secondSmall = secondBodySize < m_atr * 0.3;
   
   // Third candle: bullish
   bool thirdBullish = iClose(m_symbol, m_timeframe, shift) > iOpen(m_symbol, m_timeframe, shift);
   
   // Gap between first and second candle
   bool hasGap1 = iHigh(m_symbol, m_timeframe, shift + 1) < iLow(m_symbol, m_timeframe, shift + 2);
   
   // Gap between second and third candle
   bool hasGap2 = iLow(m_symbol, m_timeframe, shift) > iHigh(m_symbol, m_timeframe, shift + 1);
   
   // Third candle closes well into first candle body
   double firstBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 2) - iOpen(m_symbol, m_timeframe, shift + 2));
   double thirdBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift) - iOpen(m_symbol, m_timeframe, shift));
   bool thirdStrong = thirdBodySize > firstBodySize * 0.5;
   
   // Check overall pattern
   bool isPattern = firstBearish && secondSmall && thirdBullish && thirdStrong;
   
   // Adjust for sensitivity
   if(m_candlePatternSensitivity > 7) {
      // More relaxed rules for high sensitivity
      return isPattern;
   } else {
      // Stricter rules for lower sensitivity
      return isPattern && (hasGap1 || hasGap2);
   }
}

//+------------------------------------------------------------------+
//| Check for evening star pattern                                   |
//+------------------------------------------------------------------+
bool CMarketStructure::IsEveningStar(int shift) {
   if(shift + 2 >= Bars(m_symbol, m_timeframe)) return false;
   
   // First candle: bullish
   bool firstBullish = iClose(m_symbol, m_timeframe, shift + 2) > iOpen(m_symbol, m_timeframe, shift + 2);
   
   // Second candle: small body (doji or small candle)
   double secondBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 1) - iOpen(m_symbol, m_timeframe, shift + 1));
   bool secondSmall = secondBodySize < m_atr * 0.3;
   
   // Third candle: bearish
   bool thirdBearish = iClose(m_symbol, m_timeframe, shift) < iOpen(m_symbol, m_timeframe, shift);
   
   // Gap between first and second candle
   bool hasGap1 = iLow(m_symbol, m_timeframe, shift + 1) > iHigh(m_symbol, m_timeframe, shift + 2);
   
   // Gap between second and third candle
   bool hasGap2 = iHigh(m_symbol, m_timeframe, shift) < iLow(m_symbol, m_timeframe, shift + 1);
   
   // Third candle closes well into first candle body
   double firstBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift + 2) - iOpen(m_symbol, m_timeframe, shift + 2));
   double thirdBodySize = MathAbs(iClose(m_symbol, m_timeframe, shift) - iOpen(m_symbol, m_timeframe, shift));
   bool thirdStrong = thirdBodySize > firstBodySize * 0.5;
   
   // Check overall pattern
   bool isPattern = firstBullish && secondSmall && thirdBearish && thirdStrong;
   
   // Adjust for sensitivity
   if(m_candlePatternSensitivity > 7) {
      // More relaxed rules for high sensitivity
      return isPattern;
   } else {
      // Stricter rules for lower sensitivity
      return isPattern && (hasGap1 || hasGap2);
   }
}

//+------------------------------------------------------------------+
//| Check for hammer pattern                                         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsHammer(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   double lowerShadow, upperShadow;
   
   // Calculate shadows based on whether candle is bullish or bearish
   if(close >= open) { // Bullish candle
      upperShadow = high - close;
      lowerShadow = open - low;
   } else { // Bearish candle
      upperShadow = high - open;
      lowerShadow = close - low;
   }
   
   // Check if it's a hammer
   bool isHammer = (lowerShadow > bodySize * 2) && // Lower shadow is at least twice the body size
                  (upperShadow < bodySize * 0.1) && // Very small or no upper shadow
                  (bodySize / totalSize < 0.3); // Body is relatively small compared to total candle size
   
   // Need prior downtrend for valid hammer
   bool priorDowntrend = true;
   double sum = 0;
   for(int i = shift + 1; i <= shift + 5; i++) {
      if(i < Bars(m_symbol, m_timeframe))
         sum += iClose(m_symbol, m_timeframe, i);
   }
   double avgClose = sum / 5;
   priorDowntrend = (avgClose > close);
   
   return isHammer && priorDowntrend;
}

//+------------------------------------------------------------------+
//| Check for shooting star pattern                                  |
//+------------------------------------------------------------------+
bool CMarketStructure::IsShootingStar(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   double lowerShadow, upperShadow;
   
   // Calculate shadows based on whether candle is bullish or bearish
   if(close >= open) { // Bullish candle
      upperShadow = high - close;
      lowerShadow = open - low;
   } else { // Bearish candle
      upperShadow = high - open;
      lowerShadow = close - low;
   }
   
   // Check if it's a shooting star
   bool isShootingStar = (upperShadow > bodySize * 2) && // Upper shadow is at least twice the body size
                        (lowerShadow < bodySize * 0.1) && // Very small or no lower shadow
                        (bodySize / totalSize < 0.3); // Body is relatively small compared to total candle size
   
   // Need prior uptrend for valid shooting star
   bool priorUptrend = true;
   double sum = 0;
   for(int i = shift + 1; i <= shift + 5; i++) {
      if(i < Bars(m_symbol, m_timeframe))
         sum += iClose(m_symbol, m_timeframe, i);
   }
   double avgClose = sum / 5;
   priorUptrend = (avgClose < close);
   
   return isShootingStar && priorUptrend;
}

//+------------------------------------------------------------------+
//| Check for doji pattern                                           |
//+------------------------------------------------------------------+
bool CMarketStructure::IsDoji(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   // Body should be very small compared to total candle size
   return (bodySize / totalSize < 0.1 * (11 - m_candlePatternSensitivity) / 10.0);
}

//+------------------------------------------------------------------+
//| Check for pin bar pattern                                        |
//+------------------------------------------------------------------+
bool CMarketStructure::IsPinBar(int shift) {
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);
   
   double bodySize = MathAbs(close - open);
   double totalSize = high - low;
   
   if(totalSize <= 0) return false; // Avoid division by zero
   
   double bodyCenterPrice = (open + close) / 2.0;
   double upperPart = high - bodyCenterPrice;
   double lowerPart = bodyCenterPrice - low;
   
   bool isPinBar = false;
   
   // Bullish pin bar (tail pointing down)
   if(lowerPart / totalSize > 0.6 && bodySize / totalSize < 0.3) {
      isPinBar = true;
   }
   
   // Bearish pin bar (tail pointing up)
   if(upperPart / totalSize > 0.6 && bodySize / totalSize < 0.3) {
      isPinBar = true;
   }
   
   return isPinBar;
}

//+------------------------------------------------------------------+
//| Detect Wyckoff phase                                             |
//+------------------------------------------------------------------+
ENUM_WYCKOFF_PHASE CMarketStructure::DetectWyckoffPhase(int lookback) {
   // Reset spring/upthrust flags
   m_hasSpringPattern = false;
   m_hasUpthrustPattern = false;
   
   // Implement Wyckoff phase detection logic
   // Simplified implementation for demonstration
   double closes[], volumes[];
   double highestHigh = 0, lowestLow = 999999;
   double volumeSum = 0;
   
   ArrayResize(closes, lookback);
   ArrayResize(volumes, lookback);
   
   // Gather data
   for(int i = 0; i < lookback; i++) {
      closes[i] = iClose(m_symbol, m_timeframe, i);
      volumes[i] = iVolume(m_symbol, m_timeframe, i);
      highestHigh = MathMax(highestHigh, iHigh(m_symbol, m_timeframe, i));
      lowestLow = MathMin(lowestLow, iLow(m_symbol, m_timeframe, i));
      volumeSum += volumes[i];
   }
   
   // Calculate average volume
   double avgVolume = volumeSum / lookback;
   
   // Analysis
   double currentClose = closes[0];
   double currentVolume = volumes[0];
   
   // Check for spring pattern (break of support followed by higher close)
   for(int i = 1; i < lookback - 5; i++) {
      double prevLow = iLow(m_symbol, m_timeframe, i);
      double currentLow = iLow(m_symbol, m_timeframe, i-1);
      
      // Look for a break of previous low followed by price returning above it
      if(currentLow < prevLow && iClose(m_symbol, m_timeframe, i-1) > prevLow) {
         // Check if volume increased on the spring day
         if(iVolume(m_symbol, m_timeframe, i-1) > avgVolume * 1.3) {
            m_hasSpringPattern = true;
            break;
         }
      }
   }
   
   // Check for upthrust pattern (break of resistance followed by lower close)
   for(int i = 1; i < lookback - 5; i++) {
      double prevHigh = iHigh(m_symbol, m_timeframe, i);
      double currentHigh = iHigh(m_symbol, m_timeframe, i-1);
      
      // Look for a break of previous high followed by price returning below it
      if(currentHigh > prevHigh && iClose(m_symbol, m_timeframe, i-1) < prevHigh) {
         // Check if volume increased on the upthrust day
         if(iVolume(m_symbol, m_timeframe, i-1) > avgVolume * 1.3) {
            m_hasUpthrustPattern = true;
            break;
         }
      }
   }
   
   // Analyze volume and price patterns to determine Wyckoff phase
   // This is a simplified implementation
   
   // Check for accumulation phase
   bool hasLowVolumeSelloffs = false;
   bool hasHigherLows = true;
   
   for(int i = 10; i < lookback - 10 && i < 50; i++) {
      // Check for selling climax (sharp drop with high volume)
      if(closes[i] < closes[i+1] * 0.99 && volumes[i] > avgVolume * 1.5) {
         hasLowVolumeSelloffs = true;
      }
      
      // Check for higher lows
      if(i % 5 == 0) { // Check every 5 bars
         if(iLow(m_symbol, m_timeframe, i) < iLow(m_symbol, m_timeframe, i+5)) {
            hasHigherLows = false;
            break;
         }
      }
   }
   
   if(m_hasSpringPattern && hasLowVolumeSelloffs && currentClose < highestHigh * 0.85) {
      m_currentWyckoffPhase = WYCKOFF_ACCUMULATION;
      return WYCKOFF_ACCUMULATION;
   }
   
   // Check for distribution phase
   bool hasLowVolumePushups = false;
   bool hasLowerHighs = true;
   
   for(int i = 10; i < lookback - 10 && i < 50; i++) {
      // Check for buying climax (sharp rise with high volume)
      if(closes[i] > closes[i+1] * 1.01 && volumes[i] > avgVolume * 1.5) {
         hasLowVolumePushups = true;
      }
      
      // Check for lower highs
      if(i % 5 == 0) { // Check every 5 bars
         if(iHigh(m_symbol, m_timeframe, i) > iHigh(m_symbol, m_timeframe, i+5)) {
            hasLowerHighs = false;
            break;
         }
      }
   }
   
   if(m_hasUpthrustPattern && hasLowVolumePushups && currentClose > lowestLow * 1.15) {
      m_currentWyckoffPhase = WYCKOFF_DISTRIBUTION;
      return WYCKOFF_DISTRIBUTION;
   }
   
   // Check for markup phase
   if(currentClose > highestHigh * 0.95 && currentVolume > avgVolume * 1.2) {
      m_currentWyckoffPhase = WYCKOFF_MARKUP;
      return WYCKOFF_MARKUP;
   }
   
   // Check for markdown phase
   if(currentClose < lowestLow * 1.05 && currentVolume > avgVolume * 1.2) {
      m_currentWyckoffPhase = WYCKOFF_MARKDOWN;
      return WYCKOFF_MARKDOWN;
   }
   
   // No clear phase detected
   m_currentWyckoffPhase = WYCKOFF_NONE;
   return WYCKOFF_NONE;
}

//+------------------------------------------------------------------+
//| Check if current pattern is bullish                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBullishCandlePattern() {
   return m_lastPattern.candlePattern == PATTERN_BULLISH_ENGULFING ||
          m_lastPattern.candlePattern == PATTERN_MORNING_STAR ||
          m_lastPattern.candlePattern == PATTERN_HAMMER ||
          (m_lastPattern.candlePattern == PATTERN_PINBAR && m_lastPattern.patternDirection > 0);
}

//+------------------------------------------------------------------+
//| Check if current pattern is bearish                              |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBearishCandlePattern() {
   return m_lastPattern.candlePattern == PATTERN_BEARISH_ENGULFING ||
          m_lastPattern.candlePattern == PATTERN_EVENING_STAR ||
          m_lastPattern.candlePattern == PATTERN_SHOOTING_STAR ||
          (m_lastPattern.candlePattern == PATTERN_PINBAR && m_lastPattern.patternDirection < 0);
}

//+------------------------------------------------------------------+
//| Set sensitivity levels for pattern detection                      |
//+------------------------------------------------------------------+
void CMarketStructure::SetPatternSensitivity(int candleSensitivity, int harmonicSensitivity, int wyckoffSensitivity) {
   // Ensure values are within valid range
   m_candlePatternSensitivity = MathMax(1, MathMin(10, candleSensitivity));
   m_harmonicPatternSensitivity = MathMax(1, MathMin(10, harmonicSensitivity));
   m_wyckoffSensitivity = MathMax(1, MathMin(10, wyckoffSensitivity));
}

//+------------------------------------------------------------------+
//| Calculate current market volatility                              |
//+------------------------------------------------------------------+
double CMarketStructure::CalculateVolatility() {
   // Use ATR as volatility measure
   double currentATR = m_atr;
   
   // Calculate ATR relative to its average over a longer period
   double atrSum = 0;
   double atrArray[];
   ArraySetAsSeries(atrArray, true);
   
   int atrHandle = iATR(m_symbol, m_timeframe, m_atrPeriod);
   if(atrHandle != INVALID_HANDLE) {
      if(CopyBuffer(atrHandle, 0, 0, 20, atrArray) > 0) {
         for(int i = 0; i < 20; i++) {
            atrSum += atrArray[i];
         }
      }
      IndicatorRelease(atrHandle);
   }
   
   double avgATR = atrSum / 20;
   
   // Return ratio of current ATR to average ATR
   if(avgATR > 0)
      return currentATR / avgATR;
   else
      return 1.0;
}

//+------------------------------------------------------------------+
//| Phân tích chế độ thị trường                                       |
//+------------------------------------------------------------------+
ENUM_MARKET_MODE CMarketStructure::GetMarketMode() {
   ENUM_MARKET_STRUCTURE structure = GetMarketStructure();
   double hurstValue = m_hurstInfo.value;
   double volatility = GetVolatility();
   bool isBreakout = IsBreakout();
   
   // Xác định chế độ thị trường dựa vào cấu trúc và Hurst exponent
   if(structure == MARKET_STRONG_UPTREND || structure == MARKET_STRONG_DOWNTREND) {
      if(isBreakout)
         return MARKET_MODE_VOLATILE; // Đột phá trong xu hướng mạnh thường có biến động cao
      else
         return MARKET_MODE_TRENDING; // Xu hướng rõ ràng
   }
   else if(structure == MARKET_RANGING) {
      return MARKET_MODE_RANGING; // Thị trường đi ngang
   }
   else if(structure == MARKET_VOLATILE || volatility > 1.5) {
      return MARKET_MODE_VOLATILE; // Thị trường biến động
   }
   else if(IsPotentialReversal()) {
      return MARKET_MODE_REVERSAL; // Có dấu hiệu đảo chiều
   }
   
   // Dựa vào Hurst
   if(hurstValue > 0.6) // Xu hướng mạnh
      return MARKET_MODE_TRENDING;
   else if(hurstValue < 0.4) // Đảo chiều mạnh
      return MARKET_MODE_REVERSAL;
   else if(hurstValue >= 0.45 && hurstValue <= 0.55) // Trung tính
      return MARKET_MODE_RANGING;
   
   // Mặc định
   return MARKET_MODE_UNKNOWN;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có đột phá thị trường không                         |
//+------------------------------------------------------------------+
bool CMarketStructure::IsBreakout() {
   // Đọc giá trị mới nhất
   double high = iHigh(m_symbol, m_timeframe, 0);
   double low = iLow(m_symbol, m_timeframe, 0);
   double close = iClose(m_symbol, m_timeframe, 0);
   
   // Tính toán các ngưỡng ATR
   double atr = GetATR();
   
   // Tìm giá cao nhất và thấp nhất trong 20 nến
   double highestHigh = 0;
   double lowestLow = DBL_MAX;
   
   for(int i = 1; i < 20; i++) {
      highestHigh = MathMax(highestHigh, iHigh(m_symbol, m_timeframe, i));
      lowestLow = MathMin(lowestLow, iLow(m_symbol, m_timeframe, i));
   }
   
   // Kiểm tra đột phá lên
   if(close > highestHigh + atr * 0.5)
      return true;
   
   // Kiểm tra đột phá xuống
   if(close < lowestLow - atr * 0.5)
      return true;
   
   // Kiểm tra đột phá Bollinger Bands
   if(close > m_bollUpper + atr * 0.3 || close < m_bollLower - atr * 0.3)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Lấy giá trị Hurst Exponent hiện tại                              |
//+------------------------------------------------------------------+
double CMarketStructure::GetHurstExponent() {
   return m_hurstInfo.value;
} 