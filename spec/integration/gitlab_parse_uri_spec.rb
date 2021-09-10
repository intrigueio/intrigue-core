require_relative '../spec_helper'
include Intrigue::Task::Gitlab

describe 'it runs on entities hosted on gitlab.com' do
  it 'should parse account' do
    result = parse_gitlab_uri('https://gitlab.com/intrigue', 'account')
    expect(result.host).to eq 'https://gitlab.com'
    expect(result.account).to eq 'intrigue'
    expect(result.project).to eq nil
  end

  it 'should parse project' do
    result = parse_gitlab_uri('https://gitlab.com/intrigue/project', 'project')
    expect(result.host).to eq 'https://gitlab.com'
    expect(result.account).to eq 'intrigue'
    expect(result.project).to eq 'project'
  end

  it 'should parse subgroup with no projects' do
    result = parse_gitlab_uri('https://gitlab.com/intriguegroup/subgroup', 'account')
    expect(result.host).to eq 'https://gitlab.com'
    expect(result.account).to eq 'intriguegroup/subgroup'
    expect(result.project).to eq nil
  end

  it 'should parse subgroup with projects' do
    result = parse_gitlab_uri('https://gitlab.com/intriguegroup/subgroup/groupb/projecta', 'project')
    expect(result.host).to eq 'https://gitlab.com'
    expect(result.account).to eq 'intriguegroup/subgroup/groupb'
    expect(result.project).to eq 'projecta'
  end
end

describe 'it runs on entities hosted on gitlab.intrigue.io' do
  it 'should parse account' do
    result = parse_gitlab_uri('https://gitlab.intrigue.io/intrigue', 'account')
    expect(result.host).to eq 'https://gitlab.intrigue.io'
    expect(result.account).to eq 'intrigue'
    expect(result.project).to eq nil
  end

  it 'should parse project' do
    result = parse_gitlab_uri('https://gitlab.intrigue.io/intrigue/project', 'project')
    expect(result.host).to eq 'https://gitlab.intrigue.io'
    expect(result.account).to eq 'intrigue'
    expect(result.project).to eq 'project'
  end

  it 'should parse subgroup with no projects' do
    result = parse_gitlab_uri('https://gitlab.intrigue.io/intriguegroup/subgroup', 'account')
    expect(result.host).to eq 'https://gitlab.intrigue.io'
    expect(result.account).to eq 'intriguegroup/subgroup'
    expect(result.project).to eq nil
  end

  it 'should parse subgroup with projects' do
    result = parse_gitlab_uri('https://gitlab.intrigue.io/intriguegroup/subgroup/groupb/more/random/strings/ftw/project', 'project')
    expect(result.host).to eq 'https://gitlab.intrigue.io'
    expect(result.account).to eq 'intriguegroup/subgroup/groupb/more/random/strings/ftw'
    expect(result.project).to eq 'project'
  end
end
