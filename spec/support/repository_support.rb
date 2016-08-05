module RepositorySupport

  def expect_update_to_clone_data_repo!
    expect(SecurityAdvisory).
      to receive(:system).
      with('git', 'clone', SecurityAdvisory::REPOSITORY, SecurityAdvisory::USER_PATH.to_s).
      and_call_original
  end

  def expect_update_to_update_data_repo!
    expect(SecurityAdvisory).
      to receive(:system).
      with('git', 'pull', 'origin', 'master').
      and_call_original
  end

  def security_advisory_load(path)
    data = YAML.load_file(path)
    advisory = SecurityAdvisory.new(
      framework:           data['framework'],
      cve:                 data['cve'],
      osvdb:               data['osvdb'],
      description:         data['description'],
      cvss_v2:             data['cvss_v2'],
      cvss_v3:             data['cvss_v3'],
      date:                data['date'],
      unaffected_versions: (data['unaffected_versions'] || []).join(':'),
      patched_versions:    (data['patched_versions'] || []).join(':')
    )
  end

end