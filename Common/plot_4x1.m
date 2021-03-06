function plot_4x1(x, y, title_, xlabel_, ylabel_, linetype, linewidth, ...
    font_size)

if nargin < 8
    font_size = 10;
end

for i = 1:4
    subplot(4, 1, i);
    plot(x, y(i,:), linetype, 'LineWidth', linewidth);  
    set(gca, 'FontName', 'Times New Roman', 'FontSize', font_size);
    hold on;
end
xlabel(xlabel_, 'interpreter', 'latex');
title(title_);

subplot(4, 1, 2);
ylabel(['$' ylabel_ '$'], 'interpreter', 'latex');
end