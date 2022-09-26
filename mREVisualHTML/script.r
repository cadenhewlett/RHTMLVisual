source('./r_files/flatten_HTML.r')

############### Library Declarations ###############
libraryRequireInstall("ggplot2");
libraryRequireInstall("plotly")
####################################################

# static list of Attribute names, 
# this is the original workaround
names = c("Activity and Mobility", "Care of the Surgical Patient", 
          "Dressing and Wound Care", "Elimination",
          "Fluid Balance", "Home Care", "Hygiene", "Infection Control", 
          "Medications", "Nutrition", "Oxygenation", "Safety and Comfort", 
          "Special Procedures", "Support through Healthcare System", 
          "Vital Signs And Physical Assessment")

# ################### Actual code ####################

# Select Data
# Note: This version involves mutating the original data frame instead of 
#       making a temp df, since I thought this was originally the issue.

# store the pre-translation row count
stoRow = nrow(dataset)

# determine the range of slider columns
slider_selections = unique(na.omit(dataset[3:(ncol(dataset) - 3)]))

# determine the range of min columns
slider_min = slider_selections[0:(length(slider_selections) / 2)]

# determine the range of max columns
slider_max = slider_selections[!(slider_selections %in% slider_min)]

# join into list, similar to python's zip()
x = mapply(list, slider_max, slider_min, SIMPLIFY = TRUE)

# for each min/max pair
for (i in 1:ncol(x)) {
  # get max
  max = x[[1, i]]
  # get min
  min = x[[2, i]]
  
  # if the sliders are in range
  if (!(max - min) == 9) {
    # add the desired row to the bottom of the DataFrame
    dataset[nrow(dataset) + 1,] =
      c(names[i],
        dataset$Score[i],
        max,
        min,
        dataset$`Importance Level`[i],
        dataset$whyDidYouSelectThatSkillLevelPleaseSelectAllThatApply[i],
        dataset$isThereAnythingThatYouWouldLikeToShareAboutThisSkill[i],
        rep(NA, times = ncol(dataset) - 7) )
  }
}

# rename the columns according to the data we really want
colnames(dataset) = c("Attribute", "Score", "Max", "Min", "toolTip_1", 
                      "toolTip_2", "toolTip_3", "Label")

##################### TOOLTIP DESIGN AND FORMATTING #########################
# The inclusion/exclusion of this section didn't impact results in my tests

# Define Tab and Enter constants for text spacing
BUFFER = ("       ")
ENTER = "\n"

# Define Label Column for Tooltip. Uses HTML for Formatting
dataset$Label =
  paste(
    # Title 1
    paste("<span style='color:#445E80;'><b>",
          paste(BUFFER, ("How important is this to me?")),
          "</b></span>", "\n", sep = ""),
    # White Space
    ENTER,
    # Data Point 1 
    paste("<span style='color:#808080;font-size:13px'><b>",
          paste(BUFFER, BUFFER, BUFFER, as.character(dataset$toolTip_1)),
          "\n</b></span>", sep = ""),
    # White Space
    ENTER,
    # Title 2
    paste("<span style='color:#445E80'><b>",
          paste("   ", "Why did you select that skill level?"),
          "</b></span>", "\n", sep = ""),
    # White Space
    ENTER,
    # Data Point 2
    paste(dataset$toolTip_3, "\n", sep = ""),
    # White Space
    ENTER,
    # Title 3
    paste("<span style='color:#445E80 '><b>",
          paste(BUFFER, "   ", ("Additional Information")),
          "</b></span>", ENTER, sep = ""),
    # White Space
    ENTER,
    
    # Manual Width Setting White Space 
    paste(paste(rep("", times = 70), collapse = " "), "\n", sep = ""),
    sep = "")

##################### Reshape Dataframe and Plot ###########################
# Reshape the dataframe to what we want
dataset = dataset[
  (stoRow + 1):nrow(dataset), # get only our injected columns
  1:length(colnames(dataset)[!is.na(colnames(dataset))]) ] # and desired cols

g = ggplot(data = dataset, aes(x = Attribute, y = Score)) 
g = g + geom_bar(stat = "identity")



# ############# Create and save widget ###############
p = (ggplotly(g) %>%
       # Define tooltip parameters
       style(hoverlabel = list(bgcolor = "white",
                               font = list(color = '#808080',
                                           family = "Segoe UI",
                                           size = 9.5),
                               align = 'left')) %>%
       # Add Tooltip with customizations
       style(text = as.character(dataset$Label), traces = 1) %>%
       # Remove unnecessary plotly buttons
       config(displaylogo = FALSE,
              modeBarButtonsToRemove = c('sendDataToCloud', 'autoScale2d',
                                         'resetScale2d', 'toggleSpikelines',
                                         'hoverClosestCartesian', 
                                         'hoverCompareCartesian',
                                         'pan2d', 'lasso2d', 'toImage')))
                                         
############# Create and save widget ###############

internalSaveWidget(p, 'out.html');
####################################################

################ Reduce paddings ###################
ReadFullFileReplaceString('out.html', 'out.html', ',"padding":[0-9]*,', ',"padding":0,')
####################################################
