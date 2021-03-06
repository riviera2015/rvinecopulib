% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vinecop.R
\name{vinecop}
\alias{vinecop}
\alias{vinecop_dist}
\title{Vine copula models}
\usage{
vinecop(data, family_set = "all", structure = NA, par_method = "mle",
  nonpar_method = "constant", mult = 1, selcrit = "bic",
  weights = numeric(), psi0 = 0.9, presel = TRUE, trunc_lvl = Inf,
  tree_crit = "tau", threshold = 0, keep_data = FALSE,
  show_trace = FALSE, cores = 1)

vinecop_dist(pair_copulas, structure)
}
\arguments{
\item{data}{a matrix or data.frame (copula data should have approximately
uniform margins).}

\item{family_set}{a character vector of families; see \code{\link[=bicop]{bicop()}} for
additional options.}

\item{structure}{an \code{rvine_structure} object, namely a compressed
representation of the vine structure, or an object that can be coerced
into one (see \code{\link[=rvine_structure]{rvine_structure()}} and \code{\link[=as_rvine_structure]{as_rvine_structure()}}).
The dimension must be \code{length(pair_copulas[[1]]) + 1}; for \code{\link[=vinecop]{vinecop()}},
\code{structure = NA} performs automatic structure selection.}

\item{par_method}{the estimation method for parametric models, either \code{"mle"}
for maximum likelihood or \code{"itau"} for inversion of Kendall's tau (only
available for one-parameter families and \code{"t"}.}

\item{nonpar_method}{the estimation method for nonparametric models, either
\code{"constant"} for the standard transformation estimator, or
\code{"linear"}/\code{"quadratic"} for the local-likelihood approximations of order
one/two.}

\item{mult}{multiplier for the smoothing parameters of nonparametric
families. Values larger than 1 make the estimate more smooth, values less
than 1 less smooth.}

\item{selcrit}{criterion for family selection, either \code{"loglik"}, \code{"aic"},
\code{"bic"}, \code{"mbic"}. For \code{vinecop()} there is the additional option \code{"mbicv"}.}

\item{weights}{optional vector of weights for each observation.}

\item{psi0}{prior probability of a non-independence copula (only used for
\code{selcrit = "mbic"} and \code{selcrit = "mbicv"}).}

\item{presel}{whether the family set should be thinned out according to
symmetry characteristics of the data.}

\item{trunc_lvl}{the truncation level of the vine copula; \code{Inf} means no
truncation, \code{NA} indicates that the truncation level should be selected
automatically by \code{\link[=mBICV]{mBICV()}}.}

\item{tree_crit}{the criterion for tree selection, one of \code{"tau"}, \code{"rho"},
\code{"hoeffd"}, or \code{"mcor"} for Kendall's \eqn{\tau}, Spearman's \eqn{\rho},
Hoeffding's \eqn{D}, and maximum correlation, respectively.}

\item{threshold}{for thresholded vine copulas; \code{NA} indicates that the
threshold should be selected automatically by \code{\link[=mBICV]{mBICV()}}.}

\item{keep_data}{whether the data should be stored (necessary for using
\code{\link[=fitted]{fitted()}}).}

\item{show_trace}{logical; whether a trace of the fitting progress should be
printed.}

\item{cores}{number of cores to use; if more than 1, estimation of pair
copulas within a tree is done in parallel.}

\item{pair_copulas}{A nested list of 'bicop_dist' objects, where
\code{pair_copulas[[t]][[e]]} corresponds to the pair-copula at edge \code{e} in
tree \code{t}.}
}
\value{
Objects inheriting from \code{vinecop_dist} for \code{\link[=vinecop_dist]{vinecop_dist()}}, and
\code{vinecop} and \code{vinecop_dist} for \code{\link[=vinecop]{vinecop()}}.

Object from the \code{vinecop_dist} class are lists containing:
\itemize{
\item \code{pair_copulas}, a list of lists. Each element of \code{pair_copulas} corresponds
to a tree, which is itself a list of \code{bicop_dist} objects, see \code{\link[=bicop_dist]{bicop_dist()}}.
\item \code{structure}, an \code{rvine_structure} object, namely a compressed
representation of the vine structure, or an object that can be coerced
into one (see \code{\link[=rvine_structure]{rvine_structure()}} and \code{\link[=as_rvine_structure]{as_rvine_structure()}}).
\item \code{npars}, a \code{numeric} with the number of (effective) parameters.
}

For objects from the \code{vinecop} class, elements of the sublists in
\code{pair_copulas} are also \code{bicop} objects, see \code{\link[=bicop]{bicop()}}. Additionally,
objects from the \code{vinecop} class contain:
\itemize{
\item \code{threshold}, the (set or estimated) threshold used for thresholding the vine.
\item \code{data} (optionally, if \code{keep_data = TRUE} was used), the dataset that was
passed to \code{\link[=vinecop]{vinecop()}}.
\item \code{controls}, a \code{list} with the set of fit controls that was passed to \code{\link[=vinecop]{vinecop()}}.
\item \code{nobs}, an \code{integer} with the number of observations that was used
to fit the model.
}
}
\description{
Automated fitting or creation of custom vine copula models
}
\details{
\code{\link[=vinecop_dist]{vinecop_dist()}} creates a vine copula by specifying a nested list of
\code{\link[=bicop_dist]{bicop_dist()}} objects and a quadratic structure matrix.

\code{\link[=vinecop]{vinecop()}} provides automated fitting for vine copula models.
The function inherits the parameters of \code{\link[=bicop]{bicop()}}.
Optionally, an \code{\link[=rvine_structure]{rvine_structure()}} or \code{\link[=rvine_matrix]{rvine_matrix()}} can be used as
input to specify the vine structure. \code{tree_crit} describes the
criterion for tree selection, one of \code{"tau"}, \code{"rho"}, \code{"hoeffd"} for
Kendall's tau, Spearman's rho, and Hoeffding's D, respectively. Additionally,
\code{threshold} allows to threshold the \code{tree_crit} and \code{trunc_lvl} to truncate
the vine copula, with \code{threshold_sel} and \code{trunc_lvl_sel} to automatically
select both parameters.
}
\examples{
# specify pair-copulas
bicop <- bicop_dist("bb1", 90, c(3, 2))
pcs <- list(
    list(bicop, bicop),  # pair-copulas in first tree 
    list(bicop)          # pair-copulas in second tree 
 )
 
# specify R-vine matrix
mat <- matrix(c(1, 2, 3, 1, 2, 0, 1, 0, 0), 3, 3) 

# set up vine copula model
vc <- vinecop_dist(pcs, mat)

# show model
summary(vc)

# simulate some data
u <- rvinecop(50, vc)

# estimate a vine copula model
fit <- vinecop(u, "par")
fit
summary(fit)
str(fit, 3)

}
