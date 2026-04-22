from app.database.connection import Base, engine

# Importer toutes les classes
from app.models.user import User
from app.models.passenger import Passenger
from app.models.driver_profile import DriverProfile
from app.models.taxi import Taxi
from app.models.zone import Zone
from app.models.ride_request import RideRequest
from app.models.ride_assignment import RideAssignment
from app.models.ride_log import RideLog
from app.models.ride_ratings import RideRating
from app.models.payment import Payment
from app.models.recurring_schedule import RecurringSchedule
from app.models.notification import Notification
from app.models.incident_report import IncidentReport
from app.models.ride_event import RideEvent

# Crée toutes les tables
Base.metadata.create_all(bind=engine)

print("Toutes les tables ont été créées !")