using Pkg;
Pkg.add("MTH229")
using Plots
Pkg.add("PlotThemes")


#############################################################################################################
#################################################   Plots   #################################################
#############################################################################################################

theme(:dark)
function plot_liquidity_pool(data0::BigFloat, data1::BigFloat, Date::DateTime)
    derivative_bounds = 6
    K = data0 * data1
    xmin = sqrt(K/derivative_bounds)
    xmax = sqrt(derivative_bounds*K)
    precision = (xmax - xmin) / 100
    x = xmin:precision:xmax; y = K ./ x
    plot(x, y, 
    xlims=(0, xmax), ylims=(0, K/xmin),
    plot_title = "USDC WETH LP on " * Dates.format(Date, "yyyy-mm-dd HH:MM"),
    )
end

function plot_Swap_rate(data0::BigFloat, data1::BigFloat)
    # Plots the amount of y tokens received given an x amount of tokens swapped
    g(x) = (997*data0*x)/(997*x+1000*data1)
    plot(g, 0, 60)
end

function plot_average_price(data0::BigFloat, data1::BigFloat)
    # adds average price paid in swap to plot
    f(x) = (997*data0*x)/(997*x+1000*data1) * (1/x)
    plot!(f, label = "Average price paid in swap", color="red")
end

function plot_rate(BinanceRate::Float64)
    # adds the price on binance for security to plot
    B(x) = (BinanceRate)
    plot!(B, label="Rate on Binance", color = "orange")
end

function plot_profit(data0::BigFloat, data1::BigFloat, BinanceRate::Float64)
    # adds the optimized profit to the plot
    # Also adds the max profit point
    p(x) = ((997*data0*x)/(997*x+1000*data1) * (1/x)-BinanceRate) * x
    plot!(p, 0, 5, label = "Profit")
    # Finding the maximum profit curve
    optimizedX = (10*sqrt(9970)*sqrt(data0*data1)-1000*data1*sqrt(BinanceRate))/(997*sqrt(BinanceRate))
    optimizedY = ((997*data0*optimizedX)/(997*optimizedX+1000*data1) * (1/optimizedX)-BinanceRate) * optimizedX
    scatter!([optimizedX], [optimizedY], label = "Max Profit Point")
end

function plot_profit_polygone(data0::BigFloat, data1::BigFloat, BinanceRate::Float64)
    # This function adds the rectangle of optimized profit to the plot.
    optimizedX = (10*sqrt(9970)*sqrt(data0*data1)-1000*data1*sqrt(BinanceRate))/(997*sqrt(BinanceRate))
    averageSwapPriceY = (997*data0*optimizedX)/(997*optimizedX+1000*data1) * (1/optimizedX)
    # creates outer coordinates for profit rectangle
    coords = [
                0 BinanceRate
                optimizedX BinanceRate
                optimizedX averageSwapPriceY
                0 averageSwapPriceY
                0 BinanceRate
                NaN NaN
             ]
    colour = if optimizedX > 0 "green" else "yellow" end
    plot!(coords[:,1], coords[:,2], label = "Profit Visualized", color=colour)
end

function clear_plot()
    # Clears the plotting screen
    plot()
end

function plot_arbitrage_oppotunity(data0::BigFloat, data1::BigFloat, BinanceRate::Float64)
    clear_plot()

    optimizedX = (10*sqrt(9970)*sqrt(data0*data1)-1000*data1*sqrt(BinanceRate))/(997*sqrt(BinanceRate))
    padding = 1
    xMin = if optimizedX > 0 padding*optimizedX*(-1) else optimizedX + padding*optimizedX end
    xMax = if optimizedX > 0 optimizedX + (padding*optimizedX) else -padding*optimizedX end

    padding = 0.01
    yInterceptAveragePrice = (997*data0*-0.001)/(997*-0.001+1000*data1) * (1/-0.001)
    yMax = if BinanceRate > yInterceptAveragePrice BinanceRate+(padding*BinanceRate) else yInterceptAveragePrice+(padding*BinanceRate) end
    yMin = if BinanceRate < yInterceptAveragePrice BinanceRate-(padding*BinanceRate) else yInterceptAveragePrice-(padding*BinanceRate) end
    plot!(xlims=(xMin, xMax), ylims=(yMin, yMax))
    vline!([0], label="y-axis", color="grey")
    
    plot_average_price(data0, data1)
    plot_rate(BinanceRate)
    plot_profit_polygone(data0, data1, BinanceRate)
end

# data0 = convert(BigFloat, 100)
# data1 = convert(BigFloat, 10)
# BinanceRate = convert(Float64, 7)
# plot_arbitrage_oppotunity(data0, data1, BinanceRate)

println("Successfully loaded 'Plotting.jl'")