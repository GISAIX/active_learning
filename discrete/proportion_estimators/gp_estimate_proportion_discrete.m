function [expected_proportion proportion_variance] = ...
      gp_estimate_proportion_discrete(data, responses, in_train, ...
          prior_covariances, inference_method, mean_function, ...q
          covariance_function, likelihood, hypersamples, num_samples, ...
          jitter)

  if (nargin < 11)
    jitter = 1e-6;
  end
  
  [latent_means latent_covariances hypersample_weights] = ...
      estimate_latent_posterior_discrete(data, responses, in_train, ...
          prior_covariances, inference_method, mean_function, ...
          covariance_function, likelihood, hypersamples, true);
  
  [dimension num_components] = size(latent_means);
  
  components = randsample(num_components, num_samples, true, hypersample_weights);
  latent_samples = zeros(num_samples, dimension);
  
  for i = 1:num_components
    latent_samples(components == i, :) = ...
        randnorm(nnz(components == i), latent_means(:, i), ...
                 [], latent_covariances(:, :, i) + jitter * eye(dimension))';
  end
  
  trial_probabilities = resize(exp(likelihood([], num_samples, ...
          latent_samples(:), [])), num_samples, dimension);

  num_train = nnz(in_train);
  num_test = nnz(~in_train);
  total = num_train + num_test;

  expected_proportion = ...
      (num_train / total)   * mean(responses(in_train)) + ...
      (num_test  / total)   * mean(trial_probabilities(:));
  proportion_variance = ...
      (num_test  / total)^2 * var(mean(trial_probabilities, 2));

end
