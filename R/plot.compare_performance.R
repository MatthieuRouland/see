#' @importFrom effectsize change_scale
#' @export
data_plot.compare_performance <- function(x, data = NULL, ...){
  x$Model <- sprintf("%s (%s)", x$Name, x$Model)
  x$Name <- NULL
  x$Performance_Score <- NULL

  # set reference for Bayes factors to 1
  if ("BF" %in% colnames(x)) x$BF[is.na(x$BF)] <- 1

  # normalize indices, for better comparison
  x <- effectsize::change_scale(x, exclude = "Model", to = c(.1, 1))

  # recode some indices, so higher values = better fit
  for (i in c("AIC", "BIC", "RMSE", "Sigma")) {
    if (i %in% colnames(x)) {
      x[[i]] <- 1.1 - x[[i]]
    }
  }

  # remove indices with missing value, comparison makes no sense here
  x <- x[sapply(x, function(.x) !anyNA(.x))]

  x <- .reshape_to_long(x, names_to = "name", columns = 2:ncol(x))
  x$name <- factor(x$name, levels = unique(x$name))

  dataplot <- as.data.frame(x)
  attr(dataplot, "info") <- list(
    "xlab" = "",
    "ylab" = "",
    "title" = "Comparison of Model Indices",
    "legend_color" = "Models"
  )

  class(dataplot) <- c("data_plot", "see_compare_performance", "data.frame")
  dataplot
}




# Plot --------------------------------------------------------------------
#' Plot method for comparing model performances
#'
#' The \code{plot()} method for the \code{performance::compare_performance()} function.
#'
#' @inheritParams data_plot
#' @inheritParams plot.see_check_normality
#'
#' @return A ggplot2-object.
#'
#' @examples
#' library(performance)
#' data(iris)
#' lm1 <- lm(Sepal.Length ~ Species, data = iris)
#' lm2 <- lm(Sepal.Length ~ Species + Petal.Length, data = iris)
#' lm3 <- lm(Sepal.Length ~ Species * Petal.Length, data = iris)
#' result <- compare_performance(lm1, lm2, lm3)
#' result
#' plot(result)
#' @importFrom rlang .data
#' @export
plot.see_compare_performance <- function(x, size_line = 1, ...) {

  # We may think of plotting the "performance scores" as bar plots,
  # however, the "worst" model always has a score of zero, so no bar
  # is shown - this is rather confusing. One option might be to only
  # normalize indices that have a range other than 0-1, and leave
  # indices like R2 (that have a range between 0 and 1) unchanged...

  # if ("Performance_Score" %in% colnames(x)) {
  #   if (missing(size)) size <- .7
  #   x$Model <- sprintf("%s (%s)", x$Model, x$Type)
  #   p <- ggplot(x, aes(
  #     x = .data$Model,
  #     y = .data$Performance_Score
  #   )) +
  #     geom_col(width = size) +
  #     scale_y_continuous(limits = c(0, 1), labels = .percents) +
  #     labs(x = "Model", y = "Performance Score")
  # } else {

  if (!"data_plot" %in% class(x)) {
    x <- data_plot(x)
  }

  p <- ggplot(x, aes(
    x = .data$name,
    y = .data$values,
    colour = .data$Model,
    group = .data$Model,
    fill = .data$Model
  )) +
    geom_polygon(size = size_line, alpha = .05) +
    coord_radar() +
    scale_y_continuous(limits = c(0, 1), labels = NULL) +
    add_plot_attributes(x) +
    guides(fill = "none") +
    theme_radar() +
    scale_color_see()

  p
}
