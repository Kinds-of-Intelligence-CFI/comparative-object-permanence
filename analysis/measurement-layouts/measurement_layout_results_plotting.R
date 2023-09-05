###############################################################################################################################
#################################          Plotting Measurement Layout Results           ######################################
###############################################################################################################################


############################################################
###  Plotting Measurement Layout Results                 ###
###  Author: K. Voudouris (c) 2023. All Rights Reserved. ###
###  R version: 4.3.1 (2023-06-16 ucrt) (Beagle Scouts)  ###
############################################################


###############################################################################################################################
###############################################               Preamble            #############################################
###############################################################################################################################


library(tidyverse)
library(extrafont) # may need to run font_import();loadfonts() to get the fonts used here.

measurement_layout_data <- read.csv("./analysis/measurement-layouts/measurement_layout_results.csv")

normalized_results <- measurement_layout_data %>%
  transmute(`Agent Name` = Agent.Name,
            `Object Permanence Mean` = (Object.Permanence.Ability.Mean..All.- Object.Permanence.Ability.Min..All.)/(Object.Permanence.Ability.Max..All. - Object.Permanence.Ability.Min..All.),
            `Object Permanence SD` = Object.Permanence.Ability.SD..All./(Object.Permanence.Ability.Max..All. - Object.Permanence.Ability.Min..All.),
            `Object Permanence LL` = ifelse(`Object Permanence Mean` - `Object Permanence SD`>= 0, `Object Permanence Mean` - `Object Permanence SD`, 0),
            `Object Permanence UL` = ifelse(`Object Permanence Mean` + `Object Permanence SD` <= 1, `Object Permanence Mean` + `Object Permanence SD`, 1),
            `Flat Navigation Mean` = (Flat.Navigation.Ability.Mean..All. - Flat.Navigation.Ability.Min..All.)/(Flat.Navigation.Ability.Max..All. - Flat.Navigation.Ability.Min..All.),
            `Flat Navigation SD` = Flat.Navigation.Ability.SD..All./(Flat.Navigation.Ability.Max..All. - Flat.Navigation.Ability.Min..All.),
            `Flat Navigation LL` = ifelse((`Flat Navigation Mean` - `Flat Navigation SD`) >= 0, (`Flat Navigation Mean` - `Flat Navigation SD`), 0),
            `Flat Navigation UL` = ifelse(`Flat Navigation Mean` + `Flat Navigation SD` <= 1, `Flat Navigation Mean` + `Flat Navigation SD`, 1),
            `Visual Acuity Mean` = (Visual.Acuity.Ability.Mean..All. - Visual.Acuity.Ability.Min..All.)/(Visual.Acuity.Ability.Max..All. - Visual.Acuity.Ability.Min..All.),
            `Visual Acuity SD` = Visual.Acuity.Ability.SD..All./(Visual.Acuity.Ability.Max..All. - Visual.Acuity.Ability.Min..All.),
            `Visual Acuity LL` = ifelse(`Visual Acuity Mean` - `Visual Acuity SD` >= 0, `Visual Acuity Mean` - `Visual Acuity SD`, 0),
            `Visual Acuity UL` = ifelse(`Visual Acuity Mean` + `Visual Acuity SD` <= 1, `Visual Acuity Mean` + `Visual Acuity SD`, 1),
            `Lava Mean` = (Lava.Ability.Mean..All. - Lava.Ability.Min..All.)/(Lava.Ability.Max..All. - Lava.Ability.Min..All.),
            `Lava SD` = Lava.Ability.SD..All./(Lava.Ability.Max..All. - Lava.Ability.Min..All.),
            `Lava LL` = ifelse(`Lava Mean` - `Lava SD` >= 0, `Lava Mean` - `Lava SD`, 0),
            `Lava UL` = ifelse(`Lava Mean` + `Lava SD` <= 1, `Lava Mean` + `Lava SD`, 1),
            `Right Mean` = (Right.Ability.Mean..All. - Right.Ability.Min..All.)/(Right.Ability.Max..All. - Right.Ability.Min..All.),
            `Right SD` = Right.Ability.SD..All./(Right.Ability.Max..All. - Right.Ability.Min..All.),
            `Right LL` = ifelse(`Right Mean` - `Right SD` >= 0, `Right Mean` - `Right SD`, 0),
            `Right UL` = ifelse(`Right Mean` + `Right SD` <= 1, `Right Mean` + `Right SD`, 1),
            `Ahead Mean` = (Ahead.Ability.Mean..All. - Ahead.Ability.Min..All.)/(Ahead.Ability.Max..All. - Ahead.Ability.Min..All.),
            `Ahead SD` = Ahead.Ability.SD..All./(Ahead.Ability.Max..All. - Ahead.Ability.Min..All.),
            `Ahead LL` = ifelse(`Ahead Mean` - `Ahead SD` >= 0, `Ahead Mean` - `Ahead SD`, 0),
            `Ahead UL` = ifelse(`Ahead Mean` + `Ahead SD` <= 1, `Ahead Mean` + `Ahead SD`, 1),
            `Left Mean` = (Left.Ability.Mean..All. - Left.Ability.Min..All.)/(Left.Ability.Max..All. - Left.Ability.Min..All.),
            `Left SD` = Left.Ability.SD..All./(Left.Ability.Max..All. - Left.Ability.Min..All.),
            `Left LL` = ifelse(`Left Mean` - `Left SD` >= 0, `Left Mean` - `Left SD`, 0),
            `Left UL` = ifelse(`Left Mean` + `Left SD` <= 1, `Left Mean` + `Left SD`, 1),
            `PCTB Mean` = (PCTB.Ability.Mean..All. - PCTB.Ability.Min..All.)/(PCTB.Ability.Max..All. - PCTB.Ability.Min..All.),
            `PCTB SD` = PCTB.Ability.SD..All./(PCTB.Ability.Max..All. - PCTB.Ability.Min..All.),
            `PCTB LL` = ifelse(`PCTB Mean` - `PCTB SD` >= 0, `PCTB Mean` - `PCTB SD`, 0),
            `PCTB UL` = ifelse(`PCTB Mean` + `PCTB SD` <= 1, `PCTB Mean` + `PCTB SD`, 1),
            `CVChick Mean` = (CVChick.Ability.Mean..All. - CVChick.Ability.Min..All.)/(CVChick.Ability.Max..All. - CVChick.Ability.Min..All.),
            `CVChick SD` = CVChick.Ability.SD..All./(CVChick.Ability.Max..All. - CVChick.Ability.Min..All.),
            `CVChick LL` = ifelse(`CVChick Mean` - `CVChick SD` >= 0, `CVChick Mean` - `CVChick SD`, 0),
            `CVChick UL` = ifelse(`CVChick Mean` + `CVChick SD` <= 1, `CVChick Mean` + `CVChick SD`, 1),
            `Lights Out Mean` = (Lights.Out.Ability.Mean..All. - Lights.Out.Ability.Min..All.)/(Lights.Out.Ability.Max..All. - Lights.Out.Ability.Min..All.),
            `Lights Out SD` = Lights.Out.Ability.SD..All./(Lights.Out.Ability.Max..All. - Lights.Out.Ability.Min..All.),
            `Lights Out LL` = ifelse(`Lights Out Mean` - `Lights Out SD` >= 0, `Lights Out Mean` - `Lights Out SD`, 0),
            `Lights Out UL` = ifelse(`Lights Out Mean` + `Lights Out SD` <= 1, `Lights Out Mean` + `Lights Out SD`, 1)) %>%
  pivot_longer(cols = !`Agent Name`, names_to = "Ability", values_to = "Value") %>%
  mutate(Type = ifelse(str_detect(Ability, "Mean"), "Mean",
                                      ifelse(str_detect(Ability, "SD"), "SD",
                                             ifelse(str_detect(Ability, "LL"), "LL",
                                                    ifelse(str_detect(Ability, "UL"), "UL", 
                                                           NA)))),
         Ability = str_remove_all(Ability, Type),
         `Agent Ability` = paste(`Agent Name`, Ability)) %>%
  pivot_wider(names_from = Type,
              values_from = Value) %>%
  distinct()

all_plot <- ggplot(data=normalized_results, aes(x=`Agent Ability`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  #geom_hline(yintercept=1, lty=2) +  # add a dotted line at x=1 after flip
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (95% CI)") +
  theme_bw()  # use a white background


op_plot <- normalized_results %>%
  filter(Ability == "Object Permanence ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)


nav_plot <- normalized_results %>%
  filter(Ability == "Flat Navigation ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

visual_acuity_plot <- normalized_results %>%
  filter(Ability == "Visual Acuity ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

lava_plot <- normalized_results %>%
  filter(Ability == "Lava ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

right_plot <- normalized_results %>%
  filter(Ability == "Right ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

left_plot <- normalized_results %>%
  filter(Ability == "Left ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

ahead_plot <- normalized_results %>%
  filter(Ability == "Ahead ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

pctb_plot <- normalized_results %>%
  filter(Ability == "PCTB ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

cvchick_plot <- normalized_results %>%
  filter(Ability == "CVChick ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

lightsouts_plot <- normalized_results %>%
  filter(Ability == "Lights Out ") %>%
  ggplot(data=., aes(x=`Agent Name`, y=Mean, ymin=LL, ymax=UL, color = Ability)) +
  geom_pointrange() + 
  coord_flip() +  # flip coordinates (puts labels on y axis)
  xlab("Label") + ylab("Mean (+/- 1 SD)") +
  theme_minimal(base_family = "Arial", base_size = 15)

