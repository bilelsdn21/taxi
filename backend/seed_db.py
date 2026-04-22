import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from datetime import datetime, timedelta
from app.database.connection import SessionLocal, engine
from app.models.user import User, UserRoleEnum
from app.models.driver_profile import DriverProfile
from app.models.taxi import Taxi
from app.models.passenger import Passenger, PassengerTypeEnum
from app.models.zone import Zone
from app.models.ride_request import RideRequest, RequestStatusEnum
from app.models.ride_assignment import RideAssignment, AssignmentStatusEnum
from app.models.ride_log import RideLog, RideExecutionStatusEnum

def seed_database():
    db = SessionLocal()
    try:
        print("Nettoyage de la base de données...")
        db.query(RideLog).delete()
        db.query(RideAssignment).delete()
        db.query(RideRequest).delete()
        db.query(Passenger).delete()
        db.query(Taxi).delete()
        db.query(DriverProfile).delete()
        db.query(User).delete()
        db.query(Zone).delete()
        db.commit()

        print("Début de l'insertion des données de test...")

        # 1. Insertion des zones
        zone_1 = Zone(zone_name='Centre Sousse', city='Sousse')
        zone_2 = Zone(zone_name='Kantaoui', city='Sousse')
        db.add_all([zone_1, zone_2])
        db.commit()
        db.refresh(zone_1)
        db.refresh(zone_2)

        # 2. Insertion des utilisateurs (Chauffeur et Passager)
        driver = User(
            full_name='Ahmed Chauffeur',
            email='ahmed.driver@example.com',
            phone='+33612345678',
            password_hash='hashed_password_123',
            role=UserRoleEnum.driver,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            image_url='https://randomuser.me/api/portraits/men/32.jpg'
        )
        commuter = User(
            full_name='Marie Passager',
            email='marie.commuter@example.com',
            phone='+33698765432',
            password_hash='hashed_password_123',
            role=UserRoleEnum.commuter,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            image_url='https://randomuser.me/api/portraits/women/44.jpg'
        )
        db.add_all([driver, commuter])
        db.commit()
        db.refresh(driver)
        db.refresh(commuter)

        # 3. Insertion du profil chauffeur
        driver_profile = DriverProfile(
            driver_id=driver.user_id,
            license_number='PERMIS-987654',
            license_expiry=datetime.utcnow() + timedelta(days=365*2),
            total_trips=154,
            average_rating=4.8,
            image_url='https://randomuser.me/api/portraits/men/32.jpg'
        )
        db.add(driver_profile)
        db.commit()

        # 4. Insertion du taxi
        taxi = Taxi(
            driver_id=driver.user_id,
            vehicle_brand='Peugeot',
            vehicle_model='508',
            vehicle_year=2023,
            plate_number='AB-123-CD',
            availability=True,
            image_url='https://www.peugeot.fr/content/dam/peugeot/master/b2c/open/showroom/508/508-phev/508_mhp_phev_desktop.jpg'
        )
        db.add(taxi)
        db.commit()
        db.refresh(taxi)

        # 5. Insertion des passagers liés au commuter
        passenger_adult = Passenger(
            parent_user_id=commuter.user_id,
            full_name='Marie Passager',
            type=PassengerTypeEnum.adult,
            created_at=datetime.utcnow()
        )
        passenger_child = Passenger(
            parent_user_id=commuter.user_id,
            full_name='Lucas (Fils)',
            type=PassengerTypeEnum.child,
            created_at=datetime.utcnow()
        )
        db.add_all([passenger_adult, passenger_child])
        db.commit()
        db.refresh(passenger_adult)
        db.refresh(passenger_child)

        # 6. Insertion des requêtes de courses
        # Course 1: Active
        ride_req_1 = RideRequest(
            passenger_id=passenger_adult.passenger_id,
            zone_id=zone_1.zone_id,
            pickup_location='Médina de Sousse',
            dropoff_location='Gare de Sousse',
            pickup_lat=35.8270, pickup_lng=10.6385,
            dropoff_lat=35.8300, dropoff_lng=10.6350,
            pickup_time=datetime.utcnow(),
            scheduled_flag=False,
            status=RequestStatusEnum.accepted,
            estimated_distance=1.2,
            estimated_duration=5,
            created_at=datetime.utcnow()
        )
        # Course 2: Historique (terminée hier)
        ride_req_2 = RideRequest(
            passenger_id=passenger_adult.passenger_id,
            zone_id=zone_2.zone_id,
            pickup_location='Port El Kantaoui',
            dropoff_location='Mall of Sousse',
            pickup_lat=35.8931, pickup_lng=10.5975,
            dropoff_lat=35.8858, dropoff_lng=10.5735,
            pickup_time=datetime.utcnow() - timedelta(days=1),
            scheduled_flag=False,
            status=RequestStatusEnum.completed,
            estimated_distance=4.5,
            estimated_duration=12,
            created_at=datetime.utcnow() - timedelta(days=1)
        )
        # Course 3: En attente (pending)
        ride_req_3 = RideRequest(
            passenger_id=passenger_child.passenger_id,
            zone_id=zone_1.zone_id,
            pickup_location='Hôpital Sahloul',
            dropoff_location='Boujaafar Sousse',
            pickup_lat=35.8351, pickup_lng=10.5952,
            dropoff_lat=35.8322, dropoff_lng=10.6401,
            pickup_time=datetime.utcnow(),
            scheduled_flag=False,
            status=RequestStatusEnum.pending,
            estimated_distance=5.0,
            estimated_duration=15,
            created_at=datetime.utcnow()
        )
        # Course 4: En attente (pending)
        ride_req_4 = RideRequest(
            passenger_id=passenger_adult.passenger_id,
            zone_id=zone_2.zone_id,
            pickup_location='Hammam Sousse',
            dropoff_location='Université de Sousse',
            pickup_lat=35.8601, pickup_lng=10.6012,
            dropoff_lat=35.8201, dropoff_lng=10.5912,
            pickup_time=datetime.utcnow(),
            scheduled_flag=False,
            status=RequestStatusEnum.pending,
            estimated_distance=6.5,
            estimated_duration=18,
            created_at=datetime.utcnow()
        )
        # Course 5: En attente (pending)
        ride_req_5 = RideRequest(
            passenger_id=passenger_child.passenger_id,
            zone_id=zone_1.zone_id,
            pickup_location='Sousse Corniche',
            dropoff_location='Sousse Ribat',
            pickup_lat=35.8355, pickup_lng=10.6385,
            dropoff_lat=35.8276, dropoff_lng=10.6388,
            pickup_time=datetime.utcnow(),
            scheduled_flag=False,
            status=RequestStatusEnum.pending,
            estimated_distance=1.0,
            estimated_duration=4,
            created_at=datetime.utcnow()
        )
        db.add_all([ride_req_1, ride_req_2, ride_req_3, ride_req_4, ride_req_5])
        db.commit()
        db.refresh(ride_req_1)
        db.refresh(ride_req_2)
        db.refresh(ride_req_3)

        # 7. Insertion des assignations
        # Assignation 1
        assign_1 = RideAssignment(
            request_id=ride_req_1.request_id,
            taxi_id=taxi.taxi_id,
            status=AssignmentStatusEnum.accepted,
            offered_at=datetime.utcnow(),
            responded_at=datetime.utcnow(),
            acceptance_time=datetime.utcnow(),
            is_suggested=False
        )
        # Assignation 2
        assign_2 = RideAssignment(
            request_id=ride_req_2.request_id,
            taxi_id=taxi.taxi_id,
            status=AssignmentStatusEnum.accepted,
            offered_at=datetime.utcnow() - timedelta(days=1),
            responded_at=datetime.utcnow() - timedelta(days=1),
            acceptance_time=datetime.utcnow() - timedelta(days=1),
            is_suggested=False
        )
        db.add_all([assign_1, assign_2])
        db.commit()

        # 8. Insertion des journaux de courses (logs)
        # Log 1: Started
        log_1 = RideLog(
            request_id=ride_req_1.request_id,
            taxi_id=taxi.taxi_id,
            start_time=datetime.utcnow(),
            status=RideExecutionStatusEnum.started
        )
        # Log 2: Completed
        log_2 = RideLog(
            request_id=ride_req_2.request_id,
            taxi_id=taxi.taxi_id,
            start_time=datetime.utcnow() - timedelta(days=1),
            end_time=datetime.utcnow() - timedelta(days=1, hours=-1),
            actual_distance=29.0,
            actual_duration=48,
            status=RideExecutionStatusEnum.completed
        )
        db.add_all([log_1, log_2])
        db.commit()

        print("Base de données remplie avec succès !!")

    except Exception as e:
        print(f"Erreur lors du remplissage de la base: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
