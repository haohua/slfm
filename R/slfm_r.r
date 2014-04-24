#' @export
slfm_r <- function(x, ite=1000, omega=10, omega_1=omega/1000, a=2.1, b=1.1, gamma_a=1, gamma_b=1) {

  alpha <- array(0.1,c(nrow(x),1))
  sigma2 <- array(1,c(nrow(x),1))
  z <- array(0,c(nrow(x),1))
  p_star <- array(0.5,c(nrow(x),1))
  lambda <- array(0,c(1,ncol(x)))
  lambda <- t(rnorm(ncol(x)))
  m <- nrow(x)
  n <- ncol(x)
  Dinv = array(0,c(m,m))
  alpha.matrix <- array(0,c(ite,m))
  lambda.matrix <- array(0,c(ite,n))
  sigma.matrix <- array(0,c(ite,m)) 
  z.matrix <- array(0,c(ite,m))
  p.matrix <- array(0,c(ite,m))

  tryCatch({

    for(k in 1:ite) {
      for(i in 1:m) {
        # sigma sampling
        A <- a + n/2
        B <- b + 0.5*( x[i,]%*%x[i,] -2*lambda%*%x[i,]*alpha[i] +
          alpha[i]*lambda%*%t(lambda)*alpha[i])
        sigma2[i] <- 1/rgamma(1,A,rate=B) 
       
        z[i] <- ifelse(runif(1)<p_star[i],1,0)
        gamma_1 <- gamma_a + z[i]
        gamma_2 <- gamma_b + 1 - z[i]
        p <- rbeta(1, gamma_1, gamma_2)
        
        # alpha sampling
        v_alpha_0 <- 1/((1/omega) + (sum(lambda^2)/sigma2[i]))
        m_alpha_0 <- v_alpha_0*(sum(x[i,]*lambda)/sigma2[i])
        v_alpha_1 <- 1/((1/omega_1) + (sum(lambda^2)/sigma2[i]))
        m_alpha_1 <- v_alpha_1*(sum(x[i,]*lambda)/sigma2[i])
        
        if(z[i]) {
          alpha[i] <- rnorm(1,m_alpha_0,sqrt(v_alpha_0))
        } else {
          alpha[i] <- rnorm(1,m_alpha_1,sqrt(v_alpha_1))
        }
        frac_1 = dnorm(0,m_alpha_0,sqrt(v_alpha_0),log=T)-dnorm(0,0,sqrt(omega),log=T)
        frac_2 = dnorm(0,0,sqrt(omega_1),log=T)-dnorm(0,m_alpha_1,sqrt(v_alpha_1),log=T)
        p_star[i] <- p/(p + exp(frac_1+frac_2)*(1-p))
        
        Dinv[i,i] = 1/sigma2[i]

      }

      for(j in 1:ncol(x)) {
        v_lambda <- 1/(t(alpha)%*%Dinv%*%alpha + 1)
        m_lambda <- v_lambda*(t(alpha)%*%Dinv%*%x[,j])

        lambda[j] <- rnorm(1,m_lambda,sqrt(v_lambda))
      }

      alpha.matrix[k,] <- alpha
      lambda.matrix[k,] <- lambda
      sigma.matrix[k,] <- sigma2
      z.matrix[k,] <- z
      p.matrix[k,] <- p_star
    }
    p.matrix
  },error=function(e) {
    p.matrix
  })
  
}
