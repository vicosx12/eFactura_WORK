*==============================================================================
* QuantumInspiredOptimizer.prg
* Quantum-inspired optimization algorithms (Simulated Annealing, Genetic Algorithms)
* VFP 9 SP2 Compatible
*==============================================================================

Define Class QuantumInspiredOptimizer As Custom
    cName = "QuantumInspiredOptimizer"
    nPopulationSize = 50
    nGenerations = 100
    nTemperature = 1000.0
    nCoolingRate = 0.95
    
    * Initialize
    Procedure Init()
        Set Talk Off
        Set Safety Off
    EndProc
    
    * Simulated Annealing optimization
    Procedure SimulatedAnnealing(toObjectiveFunc, tnDimensions, tnMinValue, tnMaxValue)
        Local lnTemp, lnBestCost, lnCurrentCost, lnNewCost, lnProbability
        Local i, j, lnDelta
        Dimension laBestSolution[tnDimensions]
        Dimension laCurrentSolution[tnDimensions]
        Dimension laNewSolution[tnDimensions]
        
        * Initialize random solution
        For i = 1 To tnDimensions
            laCurrentSolution[i] = tnMinValue + (tnMaxValue - tnMinValue) * Rand()
            laBestSolution[i] = laCurrentSolution[i]
        EndFor
        
        lnBestCost = This.EvaluateSolution(@laCurrentSolution, toObjectiveFunc)
        lnCurrentCost = lnBestCost
        lnTemp = This.nTemperature
        
        * Annealing loop
        Do While lnTemp > 1
            * Generate neighbor solution
            For j = 1 To tnDimensions
                laNewSolution[j] = laCurrentSolution[j] + (Rand() - 0.5) * 2.0
                * Keep within bounds
                laNewSolution[j] = Max(tnMinValue, Min(tnMaxValue, laNewSolution[j]))
            EndFor
            
            lnNewCost = This.EvaluateSolution(@laNewSolution, toObjectiveFunc)
            lnDelta = lnNewCost - lnCurrentCost
            
            * Accept if better or with probability based on temperature
            If lnDelta < 0 Or Rand() < Exp(-lnDelta / lnTemp)
                For j = 1 To tnDimensions
                    laCurrentSolution[j] = laNewSolution[j]
                EndFor
                lnCurrentCost = lnNewCost
                
                * Update best if improved
                If lnCurrentCost < lnBestCost
                    For j = 1 To tnDimensions
                        laBestSolution[j] = laCurrentSolution[j]
                    EndFor
                    lnBestCost = lnCurrentCost
                EndIf
            EndIf
            
            * Cool down
            lnTemp = lnTemp * This.nCoolingRate
        EndDo
        
        * Return result
        Local loResult As Object
        loResult = CreateObject("Empty")
        AddProperty(loResult, "BestSolution", @laBestSolution)
        AddProperty(loResult, "BestCost", lnBestCost)
        AddProperty(loResult, "Iterations", This.nGenerations)
        
        Return loResult
    EndProc
    
    * Genetic Algorithm optimization
    Procedure GeneticAlgorithm(toObjectiveFunc, tnDimensions, tnMinValue, tnMaxValue)
        Local i, j, k, lnGen
        Local lnBestCost, lnTotalFitness, lnRandom, lnSum
        Dimension laPopulation[This.nPopulationSize, tnDimensions]
        Dimension laFitness[This.nPopulationSize]
        Dimension laBestSolution[tnDimensions]
        
        * Initialize population randomly
        For i = 1 To This.nPopulationSize
            For j = 1 To tnDimensions
                laPopulation[i, j] = tnMinValue + (tnMaxValue - tnMinValue) * Rand()
            EndFor
        EndFor
        
        * Evolution loop
        lnBestCost = 9999999
        For lnGen = 1 To This.nGenerations
            * Evaluate fitness
            lnTotalFitness = 0
            For i = 1 To This.nPopulationSize
                Dimension laSolution[tnDimensions]
                For j = 1 To tnDimensions
                    laSolution[j] = laPopulation[i, j]
                EndFor
                laFitness[i] = 1.0 / (1.0 + This.EvaluateSolution(@laSolution, toObjectiveFunc))
                lnTotalFitness = lnTotalFitness + laFitness[i]
                
                * Track best
                If laFitness[i] > 0 And (1.0/laFitness[i] - 1.0) < lnBestCost
                    lnBestCost = 1.0/laFitness[i] - 1.0
                    For k = 1 To tnDimensions
                        laBestSolution[k] = laPopulation[i, k]
                    EndFor
                EndIf
            EndFor
            
            * Selection, Crossover, Mutation (simplified)
            Dimension laNewPopulation[This.nPopulationSize, tnDimensions]
            For i = 1 To This.nPopulationSize
                * Tournament selection
                Local lnParent1, lnParent2
                lnParent1 = This.TournamentSelect(@laFitness)
                lnParent2 = This.TournamentSelect(@laFitness)
                
                * Crossover
                For j = 1 To tnDimensions
                    If Rand() < 0.5
                        laNewPopulation[i, j] = laPopulation[lnParent1, j]
                    Else
                        laNewPopulation[i, j] = laPopulation[lnParent2, j]
                    EndIf
                    
                    * Mutation
                    If Rand() < 0.1
                        laNewPopulation[i, j] = tnMinValue + (tnMaxValue - tnMinValue) * Rand()
                    EndIf
                EndFor
            EndFor
            
            * Replace population
            For i = 1 To This.nPopulationSize
                For j = 1 To tnDimensions
                    laPopulation[i, j] = laNewPopulation[i, j]
                EndFor
            EndFor
        EndFor
        
        * Return result
        Local loResult As Object
        loResult = CreateObject("Empty")
        AddProperty(loResult, "BestSolution", @laBestSolution)
        AddProperty(loResult, "BestCost", lnBestCost)
        AddProperty(loResult, "Generations", lnGen - 1)
        
        Return loResult
    EndProc
    
    * Evaluate solution with objective function
    Protected Procedure EvaluateSolution(taSolution, toFunc)
        * If function object provided, use it
        If VarType(toFunc) = 'O'
            Return toFunc.Evaluate(@taSolution)
        EndIf
        
        * Default: sphere function (sum of squares)
        Local lnSum, i
        lnSum = 0
        For i = 1 To Alen(taSolution)
            lnSum = lnSum + taSolution[i] * taSolution[i]
        EndFor
        Return lnSum
    EndProc
    
    * Tournament selection for genetic algorithm
    Protected Procedure TournamentSelect(taFitness)
        Local lnSize, lnIdx1, lnIdx2
        lnSize = Alen(taFitness)
        lnIdx1 = Int(Rand() * lnSize) + 1
        lnIdx2 = Int(Rand() * lnSize) + 1
        
        If taFitness[lnIdx1] > taFitness[lnIdx2]
            Return lnIdx1
        Else
            Return lnIdx2
        EndIf
    EndProc
    
    * Quantum-inspired particle swarm optimization
    Procedure QuantumPSO(toObjectiveFunc, tnDimensions, tnMinValue, tnMaxValue)
        Local i, j, lnIter
        Local lnBestCost
        Dimension laParticles[This.nPopulationSize, tnDimensions]
        Dimension laVelocities[This.nPopulationSize, tnDimensions]
        Dimension laPersonalBest[This.nPopulationSize, tnDimensions]
        Dimension laGlobalBest[tnDimensions]
        Dimension laFitness[This.nPopulationSize]
        
        * Initialize particles
        For i = 1 To This.nPopulationSize
            For j = 1 To tnDimensions
                laParticles[i, j] = tnMinValue + (tnMaxValue - tnMinValue) * Rand()
                laVelocities[i, j] = (Rand() - 0.5) * 2.0
                laPersonalBest[i, j] = laParticles[i, j]
            EndFor
        EndFor
        
        lnBestCost = 9999999
        
        * PSO iterations
        For lnIter = 1 To This.nGenerations
            For i = 1 To This.nPopulationSize
                Dimension laSolution[tnDimensions]
                For j = 1 To tnDimensions
                    laSolution[j] = laParticles[i, j]
                EndFor
                
                laFitness[i] = This.EvaluateSolution(@laSolution, toObjectiveFunc)
                
                * Update personal best
                If laFitness[i] < lnBestCost
                    lnBestCost = laFitness[i]
                    For j = 1 To tnDimensions
                        laGlobalBest[j] = laParticles[i, j]
                        laPersonalBest[i, j] = laParticles[i, j]
                    EndFor
                EndIf
            EndFor
            
            * Update velocities and positions (quantum-inspired)
            For i = 1 To This.nPopulationSize
                For j = 1 To tnDimensions
                    Local lnR1, lnR2, lnW, lnC1, lnC2
                    lnR1 = Rand()
                    lnR2 = Rand()
                    lnW = 0.5
                    lnC1 = 1.5
                    lnC2 = 1.5
                    
                    * Quantum collapse-inspired update
                    laVelocities[i, j] = lnW * laVelocities[i, j] + ;
                        lnC1 * lnR1 * (laPersonalBest[i, j] - laParticles[i, j]) + ;
                        lnC2 * lnR2 * (laGlobalBest[j] - laParticles[i, j])
                    
                    laParticles[i, j] = laParticles[i, j] + laVelocities[i, j]
                    
                    * Keep within bounds
                    laParticles[i, j] = Max(tnMinValue, Min(tnMaxValue, laParticles[i, j]))
                EndFor
            EndFor
        EndFor
        
        * Return result
        Local loResult As Object
        loResult = CreateObject("Empty")
        AddProperty(loResult, "BestSolution", @laGlobalBest)
        AddProperty(loResult, "BestCost", lnBestCost)
        AddProperty(loResult, "Iterations", lnIter - 1)
        
        Return loResult
    EndProc
EndDefine
