# Machine Learning simulations analysis
### Project for final qualifying work of a bachelor in *SPb university* of student *Burlak Alexey*
# Architecture of project

- *Literature materials/* - folder of literature helpful for work
- *ML Library/* - folder with machine learning library, made by Alexey Merkushev
- *json/* - folder of .json version of models
- *models/* - folder with simulink models, made in special converter
<hr/>
- *SimFunc.m* - class-colection of main functions 
    <br/>This class got set of constant properties to control what to show in console; 
    <br/>they named like show_*smth*
- *test_run_single_fault_with_plot.m* - script to run simulation with given parameters and plot graphs
- *DataCollector.m* - script to run data generation and export it
- *LearnMLLIB.m* - script to do test learning of neural network with "ML Library" with collected data
- *data.mat* - binary collection of data after filtration for neural network
- *data_unfiltered.mat* - binary collection of unfiltrated data for neural network
- *old_data.mat* - binary collection of data for neural network in old format

