require 'spec_helper'

describe 'node_definition' do
  context 'one role declared' do
    context 'with role inclusion' do
      let(:code) do
        <<-MANIFEST
        node 'foo' {
          $some_variable = 'value'
          include '::roles::bar'
        }
        MANIFEST
      end

      it 'should not detect problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'with role resource-like declaration' do
      let(:code) do
        <<-MANIFEST
        node 'foo' {
          $some_variable = 'value'
          class { 'role::bar: }
        }
        MANIFEST
      end

      it 'should not detect problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'with require function and parens' do
      let(:code) do
        <<-MANIFEST
        node 'foo' {
          $some_variable = 'value'
          require('role::bar')
        }
        MANIFEST
      end

      it 'should not detect problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'with contain function' do
      let(:code) do
        <<-MANIFEST
        node default {
          contain('::role::bar')
        }
        MANIFEST
      end

      it 'should not detect problems' do
        expect(problems).to have(0).problems
      end
    end
  end

  context 'declared classes not role' do
    context 'with 2 non-role classes' do
      let(:msg) { 'expected role declaration' }
      let(:code) do
        <<-MANIFEST
        node 'foo' {
          include bar
          class { '::baz': }
        }
        MANIFEST
      end

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should create 2 warnings' do
        expect(problems).to contain_warning(msg).on_line(2).in_column(11)
        expect(problems).to contain_warning(msg).on_line(3).in_column(11)
      end
    end
  end

  context 'multiple roles declared' do
    context 'with multiple role classes' do
      let(:msg) { 'expected only one role declaration' }
      let(:code) do
        <<-MANIFEST
        node 'foo' {
          include role::one
          class { '::roles::two': }
          require roles::three
          contain(::roles::four)
        }
        MANIFEST
      end

      it 'should detect 3 problems' do
        expect(problems).to have(3).problems
      end

      it 'should create 3 warnings' do
        expect(problems).to contain_warning(msg).on_line(3).in_column(11)
        expect(problems).to contain_warning(msg).on_line(4).in_column(11)
        expect(problems).to contain_warning(msg).on_line(5).in_column(11)
      end
    end
  end
end
