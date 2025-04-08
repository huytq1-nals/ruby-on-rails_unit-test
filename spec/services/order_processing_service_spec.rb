require 'rails_helper'

RSpec.describe OrderProcessingService do
  let(:api_client) { double('ApiClient') }
  let(:service) { described_class.new(api_client) }
  let!(:user) { FactoryBot.create(:user) }

  describe '#process_orders' do
    context 'when no orders exist' do
      it 'returns false' do
        expect(service.process_orders(-1)).to be false
      end
    end

    context 'when processing type A order' do
      context 'when generating CSV successfully and amount <= 150' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'A', amount: 150) }

        it 'saves the csv file' do
          time_in_seconds = 1672531199
          file_path = "spec/tmp/orders_type_A_#{user.id}_1672531199.csv"

          Timecop.freeze(Time.at(time_in_seconds)) do
            expect(service.process_orders(user.id)).to be true
            expect(File.exist?(Rails.root.join(file_path))).to be true
            content = CSV.read(Rails.root.join(file_path))
            expect(content[0]).to eq %w[ID Type Amount Flag Status Priority]
            expect(content[1]).to eq [order.id.to_s, order.order_type, order.amount.to_s, order.flag.to_s, order.status, order.priority]
            expect(content[2]).to eq nil
            expect(order.reload.status).to eq('exported')
          end  
        end
      end

      context 'when generating CSV successfully and amount > 150' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'A', amount: 151) }

        it 'saves the csv file' do
          time_in_seconds = 1672531199
          file_path = "spec/tmp/orders_type_A_#{user.id}_1672531199.csv"

          Timecop.freeze(Time.at(time_in_seconds)) do
            expect(service.process_orders(user.id)).to be true
            expect(File.exist?(Rails.root.join(file_path))).to be true
            content = CSV.read(Rails.root.join(file_path))
            expect(content[0]).to eq %w[ID Type Amount Flag Status Priority]
            expect(content[1]).to eq [order.id.to_s, order.order_type, order.amount.to_s, order.flag.to_s, order.status, order.priority]
            expect(content[2]).to eq ['', '', '', '', 'Note', 'High value order'] 
            expect(order.reload.status).to eq('exported')
          end  
        end
      end

      context 'when amount is > 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'A', amount: 201, priority: 'low') }

        it 'sets priority to high' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when amount is <= 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'A', amount: 200, priority: 'high') }

        it 'sets priority to low' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('low')
        end
      end

      context 'when database raises an exception' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'A', amount: 1, priority: 'high') }
        before do
          allow_any_instance_of(Order).to receive(:save!).and_raise(DatabaseException)
        end

        it 'updates status to db_error' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('db_error')
        end

        it 'does not change the priority' do
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when CSV raises an StandardError' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'A', amount: 1, priority: 'high') }
        before do
          allow(CSV).to receive(:open).and_raise(StandardError)
        end

        it 'changes status to export_failed' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('export_failed')
        end
      end
      
      context 'when processing fails and raise StandardError' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'A') }
        before do
          allow(service).to receive(:process_order).and_raise(StandardError)
        end
      
        it 'returns false when a StandardError is raised' do
          expect(service.process_orders(user.id)).to be false
        end
      end
    end

    context 'when processing type B order' do
      context 'when API call is successful' do
        context 'when response data is >= 50 and amount < 100 and flag is true' do
          let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 99, flag: true) }
          before do
            allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 50))
          end

          it 'updates status to processed' do
            expect(service.process_orders(user.id)).to be true
            expect(order.reload.status).to eq('processed')
          end
        end

        context 'when response data is >= 50 and amount < 100 and flag is false' do
          let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 99, flag: false) }
          before do
            allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 50))
          end

          it 'updates status to processed' do
            expect(service.process_orders(user.id)).to be true
            expect(order.reload.status).to eq('processed')
          end
        end

        context 'when response data is < 50 and amount < 100 and flag is true' do
          let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 99, flag: true) }
          before do
            allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 49))
          end

          it 'updates status to processed' do
            expect(service.process_orders(user.id)).to be true
            expect(order.reload.status).to eq('pending')
          end
        end

        context 'when response data is < 50 and amount < 100 and flag is false' do
          let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 99, flag: false) }
          before do
            allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 49))
          end

          it 'updates status to processed' do
            expect(service.process_orders(user.id)).to be true
            expect(order.reload.status).to eq('pending')
          end
        end

        context 'when response data is >= 50 and amount > 100 and flag is false' do
          let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 101, flag: false) }
          before do
            allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 50))
          end

          it 'updates status to processed' do
            expect(service.process_orders(user.id)).to be true
            expect(order.reload.status).to eq('error')
          end
        end

        context 'when response data is >= 50 and amount > 100 and flag is true' do
          let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 101, flag: true) }
          before do
            allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 50))
          end

          it 'updates status to processed' do
            expect(service.process_orders(user.id)).to be true
            expect(order.reload.status).to eq('pending')
          end
        end
      end

      context 'when API call fails' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B') }
        before do
          allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'error'))
        end
        it 'updates status to api_failure' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('api_error')
        end
      end

      context 'when API call raises an exception' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B') }
        before do
          allow(api_client).to receive(:call_api).with(order.id).and_raise(ApiException)
        end

        it 'updates status to api_error' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('api_failure')
        end
      end

      context 'when amount is > 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 201, priority: 'low') }
        before do
          allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 50))
        end

        it 'sets priority to high' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when amount is <= 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 200, priority: 'high') }
        before do
          allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 50))
        end

        it 'sets priority to low' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('low')
        end
      end

      context 'when database raises an exception' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B', amount: 1, priority: 'high') }
        before do
          allow_any_instance_of(Order).to receive(:save!).and_raise(DatabaseException)
          allow(api_client).to receive(:call_api).with(order.id).and_return(double('Response', status: 'success', data: 50))
        end

        it 'updates status to db_error' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('db_error')
        end

        it 'does not change the priority' do
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when processing fails and raise StandardError' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'B') }
        before do
          allow(service).to receive(:process_order).and_raise(StandardError)
        end
      
        it 'returns false when a StandardError is raised' do
          expect(service.process_orders(user.id)).to be false
        end
      end
    end

    context 'when processing type C order' do
      context 'when flag is true' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'C', flag: true) }

        it 'updates status to completed' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('completed')
        end
      end

      context 'when flag is false' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'C', flag: false) }
        it 'updates status to in_progress' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('in_progress')
        end
      end

      context 'when amount is > 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'C', amount: 201, priority: 'low') }

        it 'sets priority to high' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when amount is <= 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'C', amount: 200, priority: 'high') }

        it 'sets priority to low' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('low')
        end
      end

      context 'when database raises an exception' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'C', amount: 1, priority: 'high') }
        before do
          allow_any_instance_of(Order).to receive(:save!).and_raise(DatabaseException)
        end

        it 'updates status to db_error' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('db_error')
        end

        it 'does not change the priority' do
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when processing fails and raise StandardError' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'C') }
        before do
          allow(service).to receive(:process_order).and_raise(StandardError)
        end
      
        it 'returns false when a StandardError is raised' do
          expect(service.process_orders(user.id)).to be false
        end
      end
    end

    context 'when processing unknown order type' do
      let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'X') }

      it 'updates status to unknown_type' do
        expect(service.process_orders(user.id)).to be true
        expect(order.reload.status).to eq('unknown_type')
      end

      context 'when amount is > 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'X', amount: 201, priority: 'low') }

        it 'sets priority to high' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when amount is <= 200' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'X', amount: 200, priority: 'high') }

        it 'sets priority to low' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.priority).to eq('low')
        end
      end

      context 'when database raises an exception' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'X', amount: 1, priority: 'high') }
        before do
          allow_any_instance_of(Order).to receive(:save!).and_raise(DatabaseException)
        end

        it 'updates status to db_error' do
          expect(service.process_orders(user.id)).to be true
          expect(order.reload.status).to eq('db_error')
        end

        it 'does not change the priority' do
          expect(order.reload.priority).to eq('high')
        end
      end

      context 'when processing fails and raise StandardError' do
        let!(:order) { FactoryBot.create(:order, user_id: user.id, order_type: 'X') }
        before do
          allow(service).to receive(:process_order).and_raise(StandardError)
        end
      
        it 'returns false when a StandardError is raised' do
          expect(service.process_orders(user.id)).to be false
        end
      end
    end
  end
end
