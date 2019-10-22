# frozen_string_literal: true

require 'numo/libsvm'
require 'rumale/base/base_estimator'
require 'rumale/base/classifier'

module Rumale
  module SVM
    # SVC is a class that provides Kernel C-Support Vector Classifier in LIBSVM with Rumale interface.
    #
    # @example
    #   estimator = Rumale::SVM::SVC.new(reg_param: 1.0, kernel: 'rbf', gamma: 10.0, random_seed: 1)
    #   estimator.fit(training_samples, traininig_labels)
    #   results = estimator.predict(testing_samples)
    class SVC
      include Base::BaseEstimator
      include Base::Classifier

      # Create a new classifier with Kernel C-Support Vector Classifier.
      #
      # @param reg_param [Float] The regularization parameter.
      # @param kernel [String] The type of kernel function ('rbf', 'linear', 'poly', 'sigmoid', and 'precomputed').
      # @param degree [Integer] The degree parameter in polynomial kernel function.
      # @param gamma [Float] The gamma parameter in rbf/poly/sigmoid kernel function.
      # @param coef0 [Float] The coefficient in poly/sigmoid kernel function.
      # @param shrinking [Boolean] The flag indicating whether to use the shrinking heuristics.
      # @param probability [Boolean] The flag indicating whether to train the parameter for probability estimation.
      # @param cache_size [Float] The cache memory size in MB.
      # @param tol [Float] The tolerance of termination criterion.
      # @param verbose [Boolean] The flag indicating whether to output learning process message
      # @param random_seed [Integer/Nil] The seed value using to initialize the random generator.
      def initialize(reg_param: 1.0, kernel: 'rbf', degree: 3, gamma: 1.0, coef0: 0.0,
                     shrinking: true, probability: true, cache_size: 200.0, tol: 1e-3, verbose: false, random_seed: nil)
        check_params_float(reg_param: reg_param, gamma: gamma, coef0: coef0, cache_size: cache_size, tol: tol)
        check_params_integer(degree: degree)
        check_params_boolean(shrinking: shrinking, probability: probability, verbose: verbose)
        check_params_type_or_nil(Integer, random_seed: random_seed)
        @params = {}
        @params[:reg_param] = reg_param
        @params[:kernel] = kernel
        @params[:degree] = degree
        @params[:gamma] = gamma
        @params[:coef0] = coef0
        @params[:shrinking] = shrinking
        @params[:probability] = probability
        @params[:cache_size] = cache_size
        @params[:tol] = tol
        @params[:verbose] = verbose
        @params[:random_seed] = random_seed
        @model = nil
      end

      # Fit the model with given training data.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      #   If the kernel is 'precomputed', x must be a square distance matrix (shape: [n_samples, n_samples]).
      # @param y [Numo::Int32] (shape: [n_samples]) The labels to be used for fitting the model.
      # @return [SVC] The learned classifier itself.
      def fit(x, y)
        check_sample_array(x)
        check_label_array(y)
        check_sample_label_size(x, y)
        xx = precomputed_kernel? ? add_index_col(x) : x
        @model = Numo::Libsvm.train(xx, y, libsvm_params)
        self
      end

      # Calculate confidence scores for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to compute the scores.
      #   If the kernel is 'precomputed', the shape of x must be [n_samples, n_training_samples].
      # @return [Numo::DFloat] (shape: [n_samples, n_classes]) Confidence score per sample.
      def decision_function(x)
        check_sample_array(x)
        xx = precomputed_kernel? ? add_index_col(x) : x
        Numo::Libsvm.decision_function(xx, libsvm_params, @model)
      end

      # Predict class labels for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      #   If the kernel is 'precomputed', the shape of x must be [n_samples, n_training_samples].
      # @return [Numo::Int32] (shape: [n_samples]) Predicted class label per sample.
      def predict(x)
        check_sample_array(x)
        xx = precomputed_kernel? ? add_index_col(x) : x
        Numo::Int32.cast(Numo::Libsvm.predict(xx, libsvm_params, @model))
      end

      # Predict class probability for samples.
      # This method works correctly only if the probability parameter is true.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to predict the probailities.
      #   If the kernel is 'precomputed', the shape of x must be [n_samples, n_training_samples].
      # @return [Numo::DFloat] (shape: [n_samples, n_classes]) Predicted probability of each class per sample.
      def predict_proba(x)
        check_sample_array(x)
        xx = precomputed_kernel? ? add_index_col(x) : x
        Numo::Libsvm.predict_proba(xx, libsvm_params, @model)
      end

      # Dump marshal data.
      # @return [Hash] The marshal data about SVC.
      def marshal_dump
        { params: @params,
          model: @model }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @model = obj[:model]
        nil
      end

      # Return the indices of support vectors.
      # @return [Numo::Int32] (shape: [n_support_vectors])
      def support
        @model[:sv_indices]
      end

      # Return the support_vectors.
      # @return [Numo::DFloat] (shape: [n_support_vectors, n_features])
      def support_vectors
        precomputed_kernel? ? del_index_col(@model[:SV]) : @model[:SV]
      end

      # Return the number of support vectors for each class.
      # @return [Numo::Int32] (shape: [n_classes])
      def n_support
        @model[:nSV]
      end

      # Return the coefficients of the support vector in decision function.
      # @return [Numo::DFloat] (shape: [n_classes - 1, n_support_vectors])
      def duel_coef
        @model[:sv_coef]
      end

      # Return the intercepts in decision function.
      # @return [Numo::DFloat] (shape: [n_classes * (n_classes - 1) / 2])
      def intercept
        @model[:rho]
      end

      # Return the probability parameter alpha.
      # @return [Numo::DFloat] (shape: [n_classes * (n_classes - 1) / 2])
      def prob_a
        @model[:probA]
      end

      # Return the probability parameter beta.
      # @return [Numo::DFloat] (shape: [n_classes * (n_classes - 1) / 2])
      def prob_b
        @model[:probB]
      end

      private

      def add_index_col(x)
        idx = Numo::Int32.new(x.shape[0]).seq + 1
        Numo::NArray.hstack([idx.expand_dims(1), x])
      end

      def del_index_col(x)
        x[true, 1..-1].dup
      end

      def precomputed_kernel?
        @params[:kernel] == 'precomputed'
      end

      def libsvm_params
        res = @params.merge(svm_type: Numo::Libsvm::SvmType::C_SVC)
        res[:kernel_type] = case res.delete(:kernel)
                            when 'linear'
                              Numo::Libsvm::KernelType::LINEAR
                            when 'poly'
                              Numo::Libsvm::KernelType::POLY
                            when 'sigmoid'
                              Numo::Libsvm::KernelType::SIGMOID
                            when 'precomputed'
                              Numo::Libsvm::KernelType::PRECOMPUTED
                            else
                              Numo::Libsvm::KernelType::RBF
                            end
        res[:C] = res.delete(:reg_param)
        res[:eps] = res.delete(:tol)
        res
      end
    end
  end
end
