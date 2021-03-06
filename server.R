# Load packages
library("shiny")
library("plotrix")#, lib.loc = "/home/kkeenan/depends/")
library("diveRsity")#, lib.loc = "/home/kkeenan/depends/")
library("iterators")#, lib.loc = "/home/kkeenan/depends/")
library("foreach")#, lib.loc = "/home/kkeenan/depends/")
library("snow")#, lib.loc = "/home/kkeenan/depends/")
library("doSNOW")#, lib.loc = "/home/kkeenan/depends/")


shinyServer(function(input, output) {
  
  out <- reactive (function(){
    
    if(is.null(input$file)) {
      infile <- "./Test_data.txt"
    } else {
      infile <- input$file$datapath
    }
      div.part(infile = infile,
               outfile = NULL,
               gp = input$gp,
               WC_Fst = input$WC_Fst,
               bs_locus = input$bs_locus,
               bs_pairwise = input$bs_pairwise,
               bootstraps = input$bootstraps,
               Plot = FALSE,
               parallel = input$parallel)
  })
  
  #############################################################################
  # Standard stats
  #############################################################################  
  output$std <-  reactiveTable(function(){
    out <- out()
    return(as.data.frame(out$standard))    
  })
  
  #Download standard data
  output$dlstd <- downloadHandler(
    filename <- function() {
      paste("standard_", Sys.Date(), "_[diveRsity-online].txt", sep = "")
    },
    content <- function(file) {
      out <- out()
      prestd <- out$standard
      std <- cbind(rownames(prestd), prestd)
      colnames(std) <- c("Loci", colnames(prestd))
      write.table(std, file, append = FALSE, quote = FALSE,
                  sep = "\t", eol = "\r\n", row.names = FALSE)
    }
  )   
  #############################################################################
  # Estimated stats
  #############################################################################
  output$est <- reactiveTable(function(){
    out <- out()
    return(as.data.frame(out$estimate))
  })
  
  #Download standard data
  output$dlest <- downloadHandler(
    filename <- function() {
      paste("estimate_", Sys.Date(), "_[diveRsity-online].txt", sep = "")
    },
    content <- function(file) {
      out <- out()
      preest <- out$estimate
      est <- cbind(rownames(preest), preest)
      colnames(est) <- c("Loci", colnames(preest))
      write.table(est, file, append = FALSE, quote = FALSE,
                  sep = "\t", eol = "\r\n", row.names = FALSE)
    }
  )
  #############################################################################
  # Pairwise matrices
  #############################################################################
  output$pw <- reactiveTable(function(){
    out <- out()
    pw_fix <- lapply(out$pairwise, function(x){
      matrix(x, ncol = ncol(x), nrow = nrow(x))
    })
    for(i in 1:length(pw_fix)){
      pw_fix[[i]][is.na(pw_fix[[i]])] <- ""
    }
    spltr <- matrix(rep("", (ncol(pw_fix[[1]]))+1), nrow = 1, 
                    ncol = (ncol(pw_fix[[1]])+1))
    rownames(spltr) <- NULL
    rowcol <- c("",colnames(out$pairwise[[1]]))
    dimnames(rowcol) <- NULL
    spltr_nm <- matrix(c("Gst_est", rep("", (length(spltr)-1))), 
                       ncol = length(spltr), nrow = 1)
    rownames(spltr_nm) <- NULL
    pre_pw <- rbind(rowcol[-1], pw_fix[[4]])
    pw <- rbind(spltr_nm, cbind(rowcol, pre_pw))
    if(!input$WC_Fst){
      for(i in 5:6){
        spltr_nm <- matrix(c(names(out$pairwise)[i], 
                             rep("", (length(spltr)-1))), 
                           ncol = length(spltr), nrow = 1)
        rownames(spltr_nm) <- NULL
        pre_pw <- rbind(rowcol[-1], pw_fix[[i]])
        pw <- rbind(pw, spltr, spltr_nm, cbind(rowcol, pre_pw))
      }
    } else {
      for (i in c(5,6,8)){
        spltr_nm <- matrix(c(names(out$pairwise)[i], 
                             rep("", (length(spltr)-1))), 
                           ncol = length(spltr), nrow = 1)
        rownames(spltr_nm) <- NULL
        pre_pw <- rbind(rowcol[-1], pw_fix[[i]])
        pw <- rbind(pw, spltr, spltr_nm, cbind(rowcol, pre_pw))
      }
    }
    dimnames(pw) <- NULL
    return(pw)
  })
  
  #Download pairwise matrix data
  output$dlpw <- downloadHandler(
    filename <- function() {
      paste("pairwise_matrix_", Sys.Date(), "_[diveRsity-online].txt", 
            sep = "")
    },
    content <- function(file) {
      out <- out()
      pw_fix <- lapply(out$pairwise, function(x){
        matrix(x, ncol = ncol(x), nrow = nrow(x))
      })
      for(i in 1:length(pw_fix)){
        pw_fix[[i]][is.na(pw_fix[[i]])] <- ""
      }
      spltr <- matrix(rep("", (ncol(pw_fix[[1]]))+1), nrow = 1, 
                      ncol = (ncol(pw_fix[[1]])+1))
      rownames(spltr) <- NULL
      rowcol <- c("",colnames(out$pairwise[[1]]))
      dimnames(rowcol) <- NULL
      spltr_nm <- matrix(c("Gst_est", rep("", (length(spltr)-1))), 
                         ncol = length(spltr), nrow = 1)
      rownames(spltr_nm) <- NULL
      pre_pw <- rbind(rowcol[-1], pw_fix[[4]])
      pw <- rbind(spltr_nm, cbind(rowcol, pre_pw))
      if(!input$WC_Fst){
        for(i in 5:6){
          spltr_nm <- matrix(c(names(out$pairwise)[i], 
                               rep("", (length(spltr)-1))), 
                             ncol = length(spltr), nrow = 1)
          rownames(spltr_nm) <- NULL
          pre_pw <- rbind(rowcol[-1], pw_fix[[i]])
          pw <- rbind(pw, spltr, spltr_nm, cbind(rowcol, pre_pw))
        }
      } else {
        for (i in c(5,6,8)){
          spltr_nm <- matrix(c(names(out$pairwise)[i], 
                               rep("", (length(spltr)-1))), 
                             ncol = length(spltr), nrow = 1)
          rownames(spltr_nm) <- NULL
          pre_pw <- rbind(rowcol[-1], pw_fix[[i]])
          pw <- rbind(pw, spltr, spltr_nm, cbind(rowcol, pre_pw))
        }
      }
      dimnames(pw) <- NULL  
      write.table(pw, file, append = FALSE, quote = FALSE,
                  sep = "\t", eol = "\r\n", row.names = FALSE,
                  col.names = FALSE)
    }
  )
  #############################################################################
  # Locus bootstraps
  #############################################################################
  output$bs_loc <- reactiveTable(function(){
    if(input$bs_locus == TRUE){
      out <- out()
      splt <- c("--","--","--","--")
      rownames(splt) <-  NULL
      splt_nm <- c("Gst_est","","","")
      rownames(splt_nm) <- NULL
      bs_loc <- rbind(splt_nm, cbind(rownames(out$bs_locus$Gst_est),
                                 out$bs_locus$Gst_est))
      if(!input$WC_Fst){
        for (i in 5:6){
          splt_nm <- c(names(out$bs_locus)[i],"","","")
          adder <- cbind(rownames(out$bs_locus[[i]]),
                         out$bs_locus[[i]])
          suppressWarnings(bs_loc <- rbind(bs_loc, splt, splt_nm, adder))
        }
      } else {
        for (i in c(5,6,8)){
          splt_nm <- c(names(out$bs_locus)[i],"","","")
          adder <- cbind(rownames(out$bs_locus[[i]]),
                         out$bs_locus[[i]])
          suppressWarnings(bs_loc <- rbind(bs_loc, splt, splt_nm, adder))
        }
      }
      rownames(bs_loc) <- NULL
      colnames(bs_loc) <- c("Loci", "Actual", "Lower", "Upper")
      return(bs_loc)
    }
  })
  
  #Download bs _pw data
  output$dllcbs <- downloadHandler(
    filename <- function() {
      paste("Locus_bootstrap_", Sys.Date(), "_[diveRsity-online].txt", sep = "")
    },
    content <- function(file) {
      if(input$bs_locus == TRUE){
        out <- out()
        splt <- c("--","--","--","--")
        rownames(splt) <-  NULL
        splt_nm <- c("Gst_est","","","")
        rownames(splt_nm) <- NULL
        bs_loc <- rbind(splt_nm, cbind(rownames(out$bs_locus$Gst_est),
                                       out$bs_locus$Gst_est))
        if(!input$WC_Fst){
          for (i in 5:6){
            splt_nm <- c(names(out$bs_locus)[i],"","","")
            adder <- cbind(rownames(out$bs_locus[[i]]),
                           out$bs_locus[[i]])
            suppressWarnings(bs_loc <- rbind(bs_loc, splt, splt_nm, adder))
          }
        } else {
          for (i in c(5,6,8)){
            splt_nm <- c(names(out$bs_locus)[i],"","","")
            adder <- cbind(rownames(out$bs_locus[[i]]),
                           out$bs_locus[[i]])
            suppressWarnings(bs_loc <- rbind(bs_loc, splt, splt_nm, adder))
          }
        }
        rownames(bs_loc) <- NULL
        colnames(bs_loc) <- c("Loci", "Actual", "Lower", "Upper")
      }
      write.table(bs_loc, file, append = FALSE, quote = FALSE,
                  sep = "\t", eol = "\r\n", row.names = FALSE)
    }
  )
  
  ############################################################################
  # Pairwise bootstrap
  ############################################################################  
  output$pw_bs <- reactiveTable(function(){
    if(input$bs_pairwise == TRUE){
      out <- out()
      splt <- c("--","--","--","--")
      splt_nm <- c("Gst_est", "","", "")
      pw <- rbind(splt_nm, cbind(rownames(out$bs_pairwise$Gst_est),
                                 out$bs_pairwise$Gst_est))
      if(!input$WC_Fst){
        for(i in 5:6){
          splt_nm <- c(names(out$bs_pairwise)[i], "", "", "")
          adder <- cbind(rownames(out$bs_pairwise[[i]]),
                         out$bs_pairwise[[i]])
          suppressWarnings(pw <- rbind(pw, splt, splt_nm, adder))                                               
        }
      } else {
        for(i in c(5,6,8)){
          splt_nm <- c(names(out$bs_pairwise)[i], "", "", "")
          adder <- cbind(rownames(out$bs_pairwise[[i]]),
                         out$bs_pairwise[[i]])
          suppressWarnings(pw <- rbind(pw, splt, splt_nm, adder))
        }
      }
      rownames(pw) <- NULL
      colnames(pw) <- c("POPS", "Actual", "Lower", "Upper")
      return(pw)    
    }
  })
  
  #Download bs _pw data
  output$dlpwbs <- downloadHandler(
    filename <- function() {
      paste("Pairwise_bootstrap_", Sys.Date(), "_[diveRsity-online].txt",
            sep = "")
    },
    content <- function(file) {
      if(input$bs_pairwise == TRUE){
        out <- out()
        splt <- c("--","--","--","--")
        splt_nm <- c("Gst_est", "","", "")
        pw <- rbind(splt_nm, cbind(rownames(out$bs_pairwise$Gst_est),
                                   out$bs_pairwise$Gst_est))
        if(!input$WC_Fst){
          for(i in 5:6){
            splt_nm <- c(names(out$bs_pairwise)[i], "", "", "")
            adder <- cbind(rownames(out$bs_pairwise[[i]]),
                           out$bs_pairwise[[i]])
            suppressWarnings(pw <- rbind(pw, splt, splt_nm, adder))                                               
          }
        } else {
          for(i in c(5,6,8)){
            splt_nm <- c(names(out$bs_pairwise)[i], "", "", "")
            adder <- cbind(rownames(out$bs_pairwise[[i]]),
                           out$bs_pairwise[[i]])
            suppressWarnings(pw <- rbind(pw, splt, splt_nm, adder))
          }
        }
        rownames(pw) <- NULL
        colnames(pw) <- c("POPS", "Actual", "Lower", "Upper")    
      }
      
      write.table(pw, file, append = FALSE, quote = FALSE,
                  sep = "\t", eol = "\r\n", row.names = FALSE)
    }
  )
  
  #Plot attempt
  output$cor <- reactivePlot(function() {
    if(input$corplot == TRUE){
      if(is.null(input$file)) {
        infile <- "./Test_data.txt"
      } else {
        infile <- input$file$datapath
      }
      x <- readGenepop.user(infile, input$gp, FALSE)
      y <- div.part(infile = infile,
                    outfile = NULL,
                    gp = input$gp,
                    WC_Fst = TRUE,
                    bs_locus = FALSE,
                    bs_pairwise = FALSE,
                    bootstraps = 0,
                   Plot = FALSE,
                   parallel = FALSE)
      par(mfrow = c(2, 2))
      par(mar = c(4, 5, 2, 2))
      sigStar <- function(x){
        if(x$p.value < 0.001) {
          return("***")
        } else if (x$p.value < 0.01) {
          return("**")
        } else if (x$p.value < 0.05) {
          return("*")
        } else {
          return("ns")
        }
      }
      plot(y[[2]][1:(nrow(y[[2]]) - 1), 8] ~ x[[16]], pch = 16, 
           xlab = "Number of alleles", ylab = expression(hat(theta)), 
           ylim = c(0, 1), las = 1, cex.lab = 1.5)
      abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 8] ~ x[[16]]), col = "red", 
             lwd = 2)
      cor1 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 8], x[[16]])
      sig <- sigStar(cor1)
      text(x = max(x[[16]])/1.5, y = 0.8, 
           labels = paste("r = ", round(cor1$estimate[[1]], 3), " ", sig, 
                          sep = ""), cex = 2)
      plot(y[[2]][1:(nrow(y[[2]]) - 1), 4] ~ x[[16]], pch = 16, 
           xlab = "Number of alleles", ylab = expression(G[st]), 
           ylim = c(0, 1), las = 1, cex.lab = 1.5)
      abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 4] ~ x[[16]]), col = "red", 
             lwd = 2)
      cor2 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 4], x[[16]])
      sig <- sigStar(cor2)
      text(x = max(x[[16]])/1.5, y = 0.8, 
           labels = paste("r = ", round(cor2$estimate[[1]], 3), " ", sig, 
                          sep = ""), cex = 2)
      plot(y[[2]][1:(nrow(y[[2]]) - 1), 5] ~ x[[16]], pch = 16, 
           xlab = "Number of alleles", ylab = expression("G'"[st]), 
           ylim = c(0, 1), las = 1, cex.lab = 1.5)
      abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 5] ~ x[[16]]), col = "red", 
             lwd = 2)
      cor3 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 5], x[[16]])
      sig <- sigStar(cor3)
      text(x = max(x[[16]])/1.5, y = 0.8, 
           labels = paste("r = ", round(cor3$estimate[[1]], 3), " ", sig, 
                          sep = ""), cex = 2)
      plot(y[[2]][1:(nrow(y[[2]]) - 1), 6] ~ x[[16]], pch = 16, 
           xlab = "Number of alleles", ylab = expression(D[est]), 
           ylim = c(0, 1), las = 1, cex.lab = 1.5)
      abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 6] ~ x[[16]]), col = "red", 
             lwd = 2)
      cor4 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 6], x[[16]])
      sig <- sigStar(cor4)
      text(x = max(x[[16]])/1.5, y = 0.8, 
           labels = paste("r = ", round(cor4$estimate[[1]], 3), " ", sig, 
                          sep = ""), cex = 2)
    }
  })
  output$corplt <- downloadHandler(
    filename = function() {
      paste("corPlot_", Sys.Date(), "_[diveRsity-online].pdf",
            sep = "")
    },
    content = function(file) {
      temp <- tempfile()
      on.exit(unlink(temp))
      if(input$corplot == TRUE){
        if(is.null(input$file)) {
          infile <- "./Test_data.txt"
        } else {
          infile <- input$file$datapath
        }
        x <- readGenepop.user(infile, input$gp, FALSE)
        y <- div.part(infile = infile,
                      outfile = NULL,
                      gp = input$gp,
                      WC_Fst = TRUE,
                      bs_locus = FALSE,
                      bs_pairwise = FALSE,
                      bootstraps = 0,
                      Plot = FALSE,
                      parallel = FALSE)
        par(mfrow = c(2, 2))
        par(mar = c(4, 5, 2, 2))
        sigStar <- function(x){
          if(x$p.value < 0.001) {
            return("***")
          } else if (x$p.value < 0.01) {
            return("**")
          } else if (x$p.value < 0.05) {
            return("*")
          } else {
            return("ns")
          }
        }
        pdf(file = temp)
        par(mfrow = c(2,2), mar = c(5,5,2,2))
        #par(mfrow = c(2,2))
        plot(y[[2]][1:(nrow(y[[2]]) - 1), 8] ~ x[[16]], pch = 16, 
             xlab = "Number of alleles", ylab = expression(hat(theta)), 
             ylim = c(0, 1), las = 1, cex.lab = 1.5)
        abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 8] ~ x[[16]]), col = "red", 
               lwd = 2)
        cor1 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 8], x[[16]])
        sig <- sigStar(cor1)
        text(x = max(x[[16]])/1.5, y = 0.8, 
             labels = paste("r = ", round(cor1$estimate[[1]], 3), " ", sig, 
                            sep = ""), cex = 2)
        plot(y[[2]][1:(nrow(y[[2]]) - 1), 4] ~ x[[16]], pch = 16, 
             xlab = "Number of alleles", ylab = expression(G[st]), 
             ylim = c(0, 1), las = 1, cex.lab = 1.5)
        abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 4] ~ x[[16]]), col = "red", 
               lwd = 2)
        cor2 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 4], x[[16]])
        sig <- sigStar(cor2)
        text(x = max(x[[16]])/1.5, y = 0.8, 
             labels = paste("r = ", round(cor2$estimate[[1]], 3), " ", sig, 
                            sep = ""), cex = 2)
        plot(y[[2]][1:(nrow(y[[2]]) - 1), 5] ~ x[[16]], pch = 16, 
             xlab = "Number of alleles", ylab = expression("G'"[st]), 
             ylim = c(0, 1), las = 1, cex.lab = 1.5)
        abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 5] ~ x[[16]]), col = "red", 
               lwd = 2)
        cor3 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 5], x[[16]])
        sig <- sigStar(cor3)
        text(x = max(x[[16]])/1.5, y = 0.8, 
             labels = paste("r = ", round(cor3$estimate[[1]], 3), " ", sig, 
                            sep = ""), cex = 2)
        plot(y[[2]][1:(nrow(y[[2]]) - 1), 6] ~ x[[16]], pch = 16, 
             xlab = "Number of alleles", ylab = expression(D[est]), 
             ylim = c(0, 1), las = 1, cex.lab = 1.5)
        abline(lm(y[[2]][1:(nrow(y[[2]]) - 1), 6] ~ x[[16]]), col = "red", 
               lwd = 2)
        cor4 <- cor.test(y[[2]][1:(nrow(y[[2]]) - 1), 6], x[[16]])
        sig <- sigStar(cor4)
        text(x = max(x[[16]])/1.5, y = 0.8, 
             labels = paste("r = ", round(cor4$estimate[[1]], 3), " ", sig, 
                            sep = ""), cex = 2)
        dev.off()
        bytes <- readBin(temp, "raw", file.info(temp)$size)
        writeBin(bytes, file)
      }
    }
  )
      
      
})
